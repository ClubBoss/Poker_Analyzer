import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../services/pack_import_service.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/hand_data.dart';
import '../../models/v2/hero_position.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/game_type.dart';
import '../../helpers/training_pack_storage.dart';
import '../../services/pack_generator_service.dart';
import '../../services/training_spot_storage_service.dart';
import '../../services/saved_hand_manager_service.dart';
import '../../models/saved_hand.dart';
import '../../models/action_entry.dart';
import '../../services/generated_pack_history_service.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'training_pack_template_editor_screen.dart';
import '../../widgets/range_matrix_picker.dart';
import '../../widgets/preset_range_buttons.dart';
import '../training_session_screen.dart';
import '../../services/training_session_service.dart';
import '../../helpers/hand_utils.dart';

import 'package:timeago/timeago.dart' as timeago;
class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() =>
      _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState
    extends State<TrainingPackTemplateListScreen> {
  final List<TrainingPackTemplate> _templates = [];
  bool _loading = false;
  String _query = '';
  late TextEditingController _searchCtrl;
  TrainingPackTemplate? _lastRemoved;
  int _lastIndex = 0;
  GameType? _selectedType;
  String? _selectedTag;
  bool _filtersShown = false;
  String _sort = 'name';
  List<GeneratedPackInfo> _history = [];
  int _mixedCount = 20;
  bool _mixedAutoOnly = false;
  bool _endlessDrill = false;
  String _mixedStreet = 'any';
  String? _lastOpenedId;

  List<GeneratedPackInfo> _dedupHistory() {
    final map = <String, GeneratedPackInfo>{};
    for (final h in _history) {
      final existing = map[h.id];
      if (existing == null || h.ts.isAfter(existing.ts)) {
        map[h.id] = h;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.ts.compareTo(a.ts));
    return list;
  }

  void _sortTemplates() {
    switch (_sort) {
      case 'created':
        _templates.sort((a, b) {
          final r = b.createdAt.compareTo(a.createdAt);
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      case 'spots':
        _templates.sort((a, b) {
          final r = b.spots.length.compareTo(a.spots.length);
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      default:
        _templates.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _loading = true;
    TrainingPackStorage.load().then((list) {
      if (!mounted) return;
      setState(() {
        _templates.addAll(list);
        _sortTemplates();
        _loading = false;
      });
    });
    GeneratedPackHistoryService.load().then((list) {
      if (!mounted) return;
      setState(() => _history = list);
    });
  }

  void _edit(TrainingPackTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: template,
          templates: _templates,
        ),
      ),
    );
    setState(() {});
    TrainingPackStorage.save(_templates);
  }

  Future<void> _rename(TrainingPackTemplate template) async {
    final ctrl = TextEditingController(text: template.name);
    GameType type = template.gameType;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GameType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Game Type'),
                items: const [
                  DropdownMenuItem(
                      value: GameType.tournament, child: Text('Tournament')),
                  DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
                ],
                onChanged: (v) =>
                    setState(() => type = v ?? GameType.tournament),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final name = ctrl.text.trim();
      if (name.isNotEmpty) {
        setState(() {
          template.name = name;
          template.gameType = type;
        });
        TrainingPackStorage.save(_templates);
      }
    }
  }

  void _duplicate(TrainingPackTemplate template) {
    final index = _templates.indexOf(template);
    if (index == -1) return;
    final copy = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: '${template.name} (copy)',
      description: template.description,
      tags: List<String>.from(template.tags),
      spots: [
        for (final s in template.spots)
          s.copyWith(
            id: const Uuid().v4(),
            hand: HandData.fromJson(s.hand.toJson()),
            tags: List<String>.from(s.tags),
          )
      ],
      createdAt: DateTime.now(),
    );
    setState(() {
      _templates.insert(index + 1, copy);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
  }

  Future<void> _generateMissing(TrainingPackTemplate t) async {
    final missing = await t.generateMissingSpotsWithProgress(context);
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All spots already present 🎉')));
      return;
    }
    setState(() => t.spots.addAll(missing));
    TrainingPackStorage.save(_templates);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added ${missing.length} spots')));
  }

  Future<void> _nameAndEdit(TrainingPackTemplate template) async {
    final ctrl = TextEditingController(text: template.name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pack Name'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        template.name = result;
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
    }
    ctrl.dispose();
    _edit(template);
  }

  void _add() {
    final template =
        TrainingPackTemplate(
            id: const Uuid().v4(), name: 'New Pack', createdAt: DateTime.now());
    setState(() {
      _templates.add(template);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
    await GeneratedPackHistoryService.logPack(
      id: template.id,
      name: template.name,
      type: 'mistakes',
      ts: DateTime.now(),
    );
    _history = await GeneratedPackHistoryService.load();
    if (mounted) setState(() {});
    _edit(template);
  }

  Future<void> _quickGenerate() async {
    final template = await PackGeneratorService.generatePushFoldPack(
      id: const Uuid().v4(),
      name: 'Standard Pack',
      heroBbStack: 10,
      playerStacksBb: const [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: PackGeneratorService.topNHands(25).toList(),
      createdAt: DateTime.now(),
    );
    template.tags.add('auto');
    setState(() {
      _templates.add(template);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
    await GeneratedPackHistoryService.logPack(
      id: template.id,
      name: template.name,
      type: 'quick',
      ts: DateTime.now(),
    );
    _history = await GeneratedPackHistoryService.load();
    if (mounted) setState(() {});
    _nameAndEdit(template);
  }

  Future<void> _generateFinalTable() async {
    await Future.delayed(Duration.zero);
    final template =
        PackGeneratorService.generateFinalTablePack(createdAt: DateTime.now())
            .copyWith(id: const Uuid().v4());
    template.tags.add('auto');
    setState(() {
      _templates.add(template);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
    await GeneratedPackHistoryService.logPack(
      id: template.id,
      name: template.name,
      type: 'final',
      ts: DateTime.now(),
    );
    _history = await GeneratedPackHistoryService.load();
    if (mounted) setState(() {});
    _nameAndEdit(template);
  }


  HeroPosition _posFromString(String s) {
    final p = s.toUpperCase();
    if (p.startsWith('SB')) return HeroPosition.sb;
    if (p.startsWith('BB')) return HeroPosition.bb;
    if (p.startsWith('BTN')) return HeroPosition.btn;
    if (p.startsWith('CO')) return HeroPosition.co;
    if (p.startsWith('MP') || p.startsWith('HJ')) return HeroPosition.mp;
    if (p.startsWith('UTG')) return HeroPosition.utg;
    return HeroPosition.unknown;
  }

  TrainingPackSpot _spotFromHand(SavedHand hand) {
    final heroCards = hand.playerCards[hand.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final actions = <ActionEntry>[for (final a in hand.actions) if (a.street == 0) a];
    for (final a in actions) {
      if (a.playerIndex == hand.heroIndex) {
        a.ev = hand.evLoss ?? 0;
        break;
      }
    }
    final stacks = <String, double>{
      for (int i = 0; i < hand.numberOfPlayers; i++)
        '$i': (hand.stackSizes[i] ?? 0).toDouble()
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData(
        heroCards: heroCards,
        position: _posFromString(hand.heroPosition),
        heroIndex: hand.heroIndex,
        playerCount: hand.numberOfPlayers,
        stacks: stacks,
        actions: {0: actions},
      ),
      tags: List<String>.from(hand.tags),
    );
  }

  Future<void> _generateFavorites() async {
    final storage = context.read<TrainingSpotStorageService>();
    final spots = await storage.load();
    final hands = <String>{};
    for (final s in spots) {
      if (!s.tags.contains('favorite')) continue;
      if (s.playerCards.length <= s.heroIndex || s.playerCards[s.heroIndex].length < 2) continue;
      final c = s.playerCards[s.heroIndex];
      final cards = '${c[0].rank}${c[0].suit} ${c[1].rank}${c[1].suit}';
      final code = handCode(cards);
      if (code != null) hands.add(code);
    }
    if (hands.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No favorites found')));
      }
      return;
    }
    final list = hands.toList()
      ..sort((a, b) => PackGeneratorService.handRanking.indexOf(a).compareTo(
          PackGeneratorService.handRanking.indexOf(b)));
    final template = await PackGeneratorService.generatePushFoldPack(
      id: const Uuid().v4(),
      name: 'Favorites',
      heroBbStack: 10,
      playerStacksBb: const [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: list,
      createdAt: DateTime.now(),
    );
    template.tags.add('auto');
    setState(() {
      _templates.add(template);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
    await GeneratedPackHistoryService.logPack(
      id: template.id,
      name: template.name,
      type: 'fav',
      ts: DateTime.now(),
    );
    _history = await GeneratedPackHistoryService.load();
    if (mounted) setState(() {});
    _nameAndEdit(template);
  }

  Future<void> _generateTopMistakes() async {
    final manager = context.read<SavedHandManagerService>();
    final hands = manager.hands
        .where((h) => h.evLoss != null)
        .toList()
      ..sort((a, b) => (a.evLoss ?? 0).compareTo(b.evLoss ?? 0));
    if (hands.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No history')));
      }
      return;
    }
    final seen = <String>{};
    final spots = <TrainingPackSpot>[];
    for (final h in hands) {
      if (seen.add(h.id)) spots.add(_spotFromHand(h));
      if (spots.length == 10) break;
    }
    if (spots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Недостаточно данных')));
      }
      return;
    }
    final template = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Top ${spots.length} Mistakes',
      createdAt: DateTime.now(),
      spots: spots,
    );
    template.tags.add('auto');
    setState(() {
      _templates.add(template);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
    _edit(template);
  }

  Future<void> _pasteRange() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paste Range'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Hands'),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final range = PackGeneratorService.parseRangeString(ctrl.text).toList();
      if (range.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid hands found.')),
        );
      } else {
        final template = await PackGeneratorService.generatePushFoldPack(
          id: const Uuid().v4(),
          name: 'Pasted Range',
          heroBbStack: 10,
          playerStacksBb: const [10, 10],
          heroPos: HeroPosition.sb,
          heroRange: range,
          createdAt: DateTime.now(),
        );
        template.tags.add('auto');
        setState(() {
          _templates.add(template);
          _sortTemplates();
        });
        TrainingPackStorage.save(_templates);
        await GeneratedPackHistoryService.logPack(
          id: template.id,
          name: template.name,
          type: 'paste',
          ts: DateTime.now(),
        );
        _history = await GeneratedPackHistoryService.load();
        if (mounted) setState(() {});
        _nameAndEdit(template);
      }
    }
    ctrl.dispose();
  }

  Future<void> _generate() async {
    final nameCtrl = TextEditingController();
    final heroStackCtrl = TextEditingController(text: '10');
    final playerStacksCtrl = TextEditingController(text: '10,10');
    final rangeCtrl = TextEditingController();
    final selected = <String>{};
    double percent = 0;
    double bbCall = 20;
    HeroPosition pos = HeroPosition.sb;
    bool listenerAdded = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          if (!listenerAdded) {
            listenerAdded = true;
            rangeCtrl.addListener(() {
              selected
                ..clear()
                ..addAll(PackGeneratorService.parseRangeString(rangeCtrl.text));
              percent = selected.length / 169 * 100;
              setState(() {});
            });
          }
          final parsed = selected.toList()..sort();
          return AlertDialog(
            title: const Text('Generate Pack'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: heroStackCtrl,
                    decoration: const InputDecoration(labelText: 'Hero Stack'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: playerStacksCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Stacks (e.g. 10/8/20)',
                    ),
                  ),
                  DropdownButtonFormField<HeroPosition>(
                    value: pos,
                    decoration:
                        const InputDecoration(labelText: 'Hero Position'),
                    items: [
                      for (final p in HeroPosition.values)
                        DropdownMenuItem(value: p, child: Text(p.label)),
                    ],
                    onChanged: (v) =>
                        setState(() => pos = v ?? HeroPosition.sb),
                  ),
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(tabs: [
                          Tab(text: 'Text'),
                          Tab(text: 'Matrix'),
                          Tab(text: 'Presets')
                        ]),
                        SizedBox(
                          height: 280,
                          child: TabBarView(
                            children: [
                              TextField(
                                controller: rangeCtrl,
                                decoration:
                                    const InputDecoration(labelText: 'Range'),
                                maxLines: null,
                              ),
                              SingleChildScrollView(
                                child: RangeMatrixPicker(
                                  selected: selected,
                                  onChanged: (v) {
                                    selected
                                      ..clear()
                                      ..addAll(v);
                                    rangeCtrl.text =
                                        PackGeneratorService.serializeRange(v);
                                    percent = selected.length / 169 * 100;
                                  },
                                ),
                              ),
                              Column(
                                children: [
                                  PresetRangeButtons(
                                    selected: selected,
                                    onChanged: (v) {
                                      selected
                                        ..clear()
                                        ..addAll(v);
                                      rangeCtrl.text =
                                          PackGeneratorService.serializeRange(
                                              v);
                                      percent = selected.length / 169 * 100;
                                      setState(() {});
                                    },
                                  ),
                                  Slider(
                                    value: percent,
                                    min: 0,
                                    max: 100,
                                    onChanged: (v) {
                                      percent = v;
                                      selected
                                        ..clear()
                                        ..addAll(PackGeneratorService.topNHands(
                                            v.round()));
                                      rangeCtrl.text =
                                          PackGeneratorService.serializeRange(
                                              selected);
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('BB call ${bbCall.round()}%'),
                  Slider(
                    value: bbCall,
                    min: 0,
                    max: 100,
                    onChanged: (v) => setState(() => bbCall = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'In SB vs BB, hands from top ${bbCall.round()}% will trigger a call instead of fold. This affects action preview, not EV.',
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: parsed.isEmpty
                          ? [const Text('No hands yet')]
                          : [for (final h in parsed) Text('[$h]')],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'Выбрано: ${selected.length} рук (${((selected.length / 169) * 100).round()} %)\nTop-N: ${percent.round()} %'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Generate'),
              ),
            ],
          );
        },
      ),
    );
    if (ok == true) {
      final name =
          nameCtrl.text.trim().isEmpty ? 'New Pack' : nameCtrl.text.trim();
      final hero = int.tryParse(heroStackCtrl.text.trim()) ?? 0;
      final stacks = [
        for (final s in playerStacksCtrl.text.split(RegExp(r'[,/]+')))
          if (s.trim().isNotEmpty) int.tryParse(s.trim()) ?? hero
      ];
      if (stacks.isEmpty) stacks.add(hero);
      final range = selected.toList();
      final template = await PackGeneratorService.generatePushFoldPack(
        id: const Uuid().v4(),
        name: name,
        heroBbStack: hero,
        playerStacksBb: stacks,
        heroPos: pos,
        heroRange: range,
        bbCallPct: bbCall.round(),
        createdAt: DateTime.now(),
      );
      template.tags.add('auto');
      setState(() {
        _templates.add(template);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      await GeneratedPackHistoryService.logPack(
        id: template.id,
        name: template.name,
        type: 'custom',
        ts: DateTime.now(),
      );
      _history = await GeneratedPackHistoryService.load();
      if (mounted) setState(() {});
      _edit(template);
    }
    nameCtrl.dispose();
    heroStackCtrl.dispose();
    playerStacksCtrl.dispose();
    rangeCtrl.dispose();
  }

  Future<void> _export() async {
    final json = jsonEncode([for (final t in _templates) t.toJson()]);
    await Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Templates copied to clipboard')),
    );
  }

  Future<void> _import() async {
    final clip = await Clipboard.getData('text/plain');
    if (clip?.text == null || clip!.text!.trim().isEmpty) return;
    List? raw;
    try {
      raw = jsonDecode(clip.text!);
    } catch (_) {}
    if (raw is! List) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid JSON')));
      return;
    }
    final imported = [
      for (final m in raw)
        TrainingPackTemplate.fromJson(Map<String, dynamic>.from(m))
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import templates?'),
        content:
            Text('This will add ${imported.length} template(s) to your list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (ok ?? false) {
      setState(() {
        _templates.addAll(imported);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${imported.length} template(s) imported')),
      );
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final data = file.bytes != null
        ? String.fromCharCodes(file.bytes!)
        : await File(file.path!).readAsString();
    final allRows = const CsvToListConverter().convert(data.trim());
    try {
      final tpl = PackImportService.importFromCsv(
        csv: data,
        templateId: const Uuid().v4(),
        templateName: p.basenameWithoutExtension(file.name),
      );
      final skipped = allRows.length - 1 - tpl.spots.length;
      setState(() {
        _templates.add(tpl);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${tpl.spots.length} spots' +
              (skipped > 0 ? ', $skipped skipped' : '')),
        ),
      );
      _edit(tpl);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid CSV')));
    }
  }

  Future<void> _pasteCsv() async {
    final clip = await Clipboard.getData('text/plain');
    final text = clip?.text?.trim();
    if (text == null || !text.startsWith('Title,HeroPosition')) return;
    final rows = const CsvToListConverter().convert(text);
    try {
      final tpl = PackImportService.importFromCsv(
        csv: text,
        templateId: const Uuid().v4(),
        templateName: 'Pasted Pack',
      );
      final skipped = rows.length - 1 - tpl.spots.length;
      setState(() {
        _templates.add(tpl);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${tpl.spots.length} spots' +
              (skipped > 0 ? ', $skipped skipped' : '')),
        ),
      );
      _edit(tpl);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid CSV')));
    }
  }

  void _showFilters() {
    final tags = <String>{for (final t in _templates) ...t.tags};
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedType == null,
                onSelected: (_) => setState(() {
                  this.setState(() => _selectedType = null);
                }),
              ),
              ChoiceChip(
                label: const Text('Tournament'),
                selected: _selectedType == GameType.tournament,
                onSelected: (_) => setState(() {
                  this.setState(() => _selectedType = GameType.tournament);
                }),
              ),
              ChoiceChip(
                label: const Text('Cash'),
                selected: _selectedType == GameType.cash,
                onSelected: (_) => setState(() {
                  this.setState(() => _selectedType = GameType.cash);
                }),
              ),
              if (tags.isNotEmpty) ...[
                ChoiceChip(
                  label: const Text('All Tags'),
                  selected: _selectedTag == null,
                  onSelected: (_) => setState(() {
                    this.setState(() => _selectedTag = null);
                  }),
                ),
                for (final tag in tags)
                  ChoiceChip(
                    label: Text(tag),
                    selected: _selectedTag == tag,
                    onSelected: (_) => setState(() {
                      this.setState(() => _selectedTag = tag);
                    }),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startMixedDrill() async {
    final countCtrl = TextEditingController(text: _mixedCount.toString());
    bool autoOnly = _mixedAutoOnly;
    bool endless = _endlessDrill;
    String street = _mixedStreet;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Mixed Drill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: countCtrl,
                decoration: const InputDecoration(labelText: 'Spots count'),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<String>(
                value: street,
                onChanged: (v) => setState(() => street = v ?? 'any'),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('Any')),
                  DropdownMenuItem(value: 'preflop', child: Text('Preflop')),
                  DropdownMenuItem(value: 'flop', child: Text('Flop')),
                  DropdownMenuItem(value: 'turn', child: Text('Turn')),
                  DropdownMenuItem(value: 'river', child: Text('River')),
                ],
              ),
              CheckboxListTile(
                value: autoOnly,
                onChanged: (v) => setState(() => autoOnly = v ?? false),
                title: const Text('Only auto-generated'),
              ),
              CheckboxListTile(
                value: endless,
                onChanged: (v) => setState(() => endless = v ?? false),
                title: const Text('Endless Drill'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    _mixedCount = int.tryParse(countCtrl.text.trim()) ?? 0;
    _mixedAutoOnly = autoOnly;
    _endlessDrill = endless;
    _mixedStreet = street;
    await _runMixedDrill();
  }

  Future<void> _runMixedDrill() async {
    final count = _mixedCount;
    final autoOnly = _mixedAutoOnly;
    final byType = _selectedType == null
        ? _templates
        : [for (final t in _templates) if (t.gameType == _selectedType) t];
    final filtered = _selectedTag == null
        ? byType
        : [for (final t in byType) if (t.tags.contains(_selectedTag)) t];
    final shown = _query.isEmpty
        ? filtered
        : [
            for (final t in filtered)
              if (t.name.toLowerCase().contains(_query) ||
                  t.description.toLowerCase().contains(_query))
                t
          ];
    final list =
        autoOnly ? [for (final t in shown) if (t.tags.contains('auto')) t] : shown;
    final spots = <TrainingPackSpot>[
      for (final t in list)
        for (final s in t.spots)
          if (_mixedStreet == 'any')
            s
          else
            {
              'preflop': 0,
              'flop': 3,
              'turn': 4,
              'river': 5
            }[_mixedStreet] == s.hand.board.length
                ? s
                : null
        ].whereType<TrainingPackSpot>().toList();
    if (spots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Not enough spots')));
      }
      return;
    }
    spots.shuffle(Random());
    final picked =
        count <= 0 || spots.length <= count ? spots : spots.take(count).toList();
    final tpl = TrainingPackTemplate(
      id: 'mixed_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Mixed Drill',
      tags: const ['mixed', 'auto'],
      spots: picked,
      createdAt: DateTime.now(),
    );
    await GeneratedPackHistoryService.logPack(
      id: tpl.id,
      name: tpl.name,
      type: 'mixed',
      ts: DateTime.now(),
    );
    if (mounted) {
      await _openTrainingSession(
        tpl,
        persist: false,
        onSessionEnd: _endlessDrill ? _runMixedDrill : null,
      );
    }
  }

  Future<void> _openTrainingSession(
    TrainingPackTemplate template, {
    bool persist = true,
    VoidCallback? onSessionEnd,
  }) async {
    await context
        .read<TrainingSessionService>()
        .startSession(template, persist: persist);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingSessionScreen(onSessionEnd: onSessionEnd),
      ),
    );
    if (!mounted) return;
    setState(() => _lastOpenedId = template.id);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _lastOpenedId != template.id) return;
      setState(() => _lastOpenedId = null);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_filtersShown && MediaQuery.of(context).size.width < 400) {
      _filtersShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFilters());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 400;
    final tags = <String>{for (final t in _templates) ...t.tags};
    final byType = _selectedType == null
        ? _templates
        : [
            for (final t in _templates)
              if (t.gameType == _selectedType) t
          ];
    final filtered = _selectedTag == null
        ? byType
        : [
            for (final t in byType)
              if (t.tags.contains(_selectedTag)) t
          ];
    final shown = _query.isEmpty
        ? filtered
        : [
            for (final t in filtered)
              if (t.name.toLowerCase().contains(_query) ||
                  t.description.toLowerCase().contains(_query))
                t
          ];
    final history = _dedupHistory();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Packs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import',
            onPressed: _import,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _export,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) {
              setState(() {
                _sort = v;
                _sortTemplates();
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'name', child: Text('Name A–Z')),
              PopupMenuItem(value: 'created', child: Text('Newest First')),
              PopupMenuItem(value: 'spots', child: Text('Most Spots')),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'paste') _pasteCsv();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'paste', child: Text('Paste CSV')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Search packs',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() {
                                _searchCtrl.clear();
                                _query = '';
                              }),
                            ),
                    ),
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
                if (history.isNotEmpty)
                  ExpansionTile(
                    title: const Text('Recent Generated Packs'),
                    children: [
                      for (final h in history)
                        ListTile(
                          tileColor: h.id == _lastOpenedId
                              ? Theme.of(context).highlightColor
                              : null,
                          title: Text(h.name),
                          subtitle: Text(
                              '${h.type} • ${DateFormat.yMMMd().add_Hm().format(h.ts)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            tooltip: 'Start training',
                            onPressed: () async {
                              final tpl = _templates.firstWhereOrNull((t) => t.id == h.id);
                              if (tpl == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Pack not found')));
                                return;
                              }
                              await _openTrainingSession(tpl);
                            },
                          ),
                          onTap: () {
                            final tpl =
                                _templates.firstWhereOrNull((t) => t.id == h.id);
                            if (tpl != null) {
                              _edit(tpl);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pack not found')));
                            }
                          },
                        ),
                    ],
                  ),
                if (!narrow)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedType == null,
                          onSelected: (_) =>
                              setState(() => _selectedType = null),
                        ),
                        ChoiceChip(
                          label: const Text('Tournament'),
                          selected: _selectedType == GameType.tournament,
                          onSelected: (_) => setState(
                              () => _selectedType = GameType.tournament),
                        ),
                        ChoiceChip(
                          label: const Text('Cash'),
                          selected: _selectedType == GameType.cash,
                          onSelected: (_) =>
                              setState(() => _selectedType = GameType.cash),
                        ),
                        if (tags.isNotEmpty) ...[
                          ChoiceChip(
                            label: const Text('All Tags'),
                            selected: _selectedTag == null,
                            onSelected: (_) =>
                                setState(() => _selectedTag = null),
                          ),
                          for (final tag in tags)
                            ChoiceChip(
                              label: Text(tag),
                              selected: _selectedTag == tag,
                              onSelected: (_) =>
                                  setState(() => _selectedTag = tag),
                            ),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: shown.length,
                    onReorder: (oldIndex, newIndex) {
                      final item = shown[oldIndex];
                      final oldPos = _templates.indexOf(item);
                      int newPos;
                      if (newIndex >= shown.length) {
                        newPos = _templates.length;
                      } else {
                        newPos = _templates.indexOf(shown[newIndex]);
                      }
                      setState(() {
                        _templates.removeAt(oldPos);
                        _templates.insert(
                          newPos > oldPos ? newPos - 1 : newPos,
                          item,
                        );
                      });
                      TrainingPackStorage.save(_templates);
                    },
                    itemBuilder: (context, index) {
                      final t = shown[index];
                      final allEv = t.spots.isNotEmpty &&
                          t.spots.every((s) => s.heroEv != null);
                      final isNew = t.lastGeneratedAt != null &&
                          DateTime.now()
                                  .difference(t.lastGeneratedAt!)
                                  .inHours <
                              48;
                      final tile = ListTile(
                        tileColor: t.id == _lastOpenedId
                            ? Theme.of(context).highlightColor
                            : null,
                        onLongPress: () => _duplicate(t),
                        title: Row(
                          children: [
                            Expanded(child: Text(t.name)),
                            if (isNew)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Chip(
                                  label: Text('NEW',
                                      style: TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            if (allEv)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child:
                                    Text('📈', style: TextStyle(fontSize: 16)),
                              ),
                          ],
                        ),
                        subtitle: (() {
                          final items = <Widget>[];
                          if (t.description.trim().isNotEmpty) {
                            items.add(Text(
                              t.description.split('\n').first,
                              style: const TextStyle(fontSize: 12),
                            ));
                          }
                          if (t.lastGeneratedAt != null) {
                            items.add(Text(
                              'Last generated: ${timeago.format(t.lastGeneratedAt!)}',
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ));
                          }
                          if (items.isEmpty) return null;
                          if (items.length == 1) return items.first;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: items,
                          );
                        })(),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              tooltip: 'Start training',
                              onPressed: () async {
                                await _openTrainingSession(t);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.auto_fix_high),
                              tooltip: 'Generate spots',
                              onPressed: () async {
                                final generated =
                                    await t.generateSpotsWithProgress(context);
                                if (!mounted) return;
                                setState(() => t.spots.addAll(generated));
                                TrainingPackStorage.save(_templates);
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'rename') _rename(t);
                                if (v == 'duplicate') _duplicate(t);
                                if (v == 'missing') _generateMissing(t);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text('✏️ Rename'),
                                ),
                                PopupMenuItem(
                                  value: 'duplicate',
                                  child: Text('📄 Duplicate'),
                                ),
                                PopupMenuItem(
                                  value: 'missing',
                                  child: Text('Generate Missing'),
                                ),
                              ],
                            ),
                            if (narrow)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _edit(t),
                              )
                            else
                              TextButton(
                                onPressed: () => _edit(t),
                                child: const Text('📝 Edit'),
                              ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _duplicate(t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete pack?'),
                                    content:
                                        Text('“${t.name}” will be removed.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel')),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (ok ?? false) {
                                  final index = _templates.indexOf(t);
                                  setState(() {
                                    _lastRemoved = t;
                                    _lastIndex = index;
                                    _templates.removeAt(index);
                                  });
                                  TrainingPackStorage.save(_templates);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Deleted'),
                                      action: SnackBarAction(
                                        label: 'UNDO',
                                        onPressed: () {
                                          if (_lastRemoved != null) {
                                            setState(() => _templates.insert(
                                                _lastIndex, _lastRemoved!));
                                            TrainingPackStorage.save(
                                                _templates);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                      return Container(
                        key: ValueKey(t.id),
                        child: Row(
                          children: [
                            if (!_loading)
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                            Expanded(child: tile),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (narrow)
            FloatingActionButton(
              heroTag: 'filterTplFab',
              onPressed: _showFilters,
              child: const Icon(Icons.filter_list),
            ),
          if (narrow) const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'quickGenTplFab',
            onPressed: _quickGenerate,
            label: const Text('Quick Generate'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'finalTableTplFab',
            onPressed: () => _generateFinalTable(),
            tooltip: 'Generate Final Table Pack',
            label: const Text('Final Table'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'favoritesTplFab',
            onPressed: _generateFavorites,
            icon: const Icon(Icons.star),
            label: const Text('Favorites Pack'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'topMistakesTplFab',
            onPressed: _generateTopMistakes,
            tooltip: 'Generate Top Mistakes Pack',
            label: const Text('Top 10 Mistakes'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'mixedDrillFab',
            icon: const Icon(Icons.shuffle),
            label: const Text('Mixed Drill'),
            onPressed: _startMixedDrill,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'pasteRangeTplFab',
            onPressed: _pasteRange,
            icon: const Icon(Icons.content_paste),
            label: const Text('Paste Range'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'genTplFab',
            onPressed: _generate,
            label: const Text('➕ Generate Pack'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'importCsvTplFab',
            onPressed: _importCsv,
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addTplFab',
            onPressed: _add,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
