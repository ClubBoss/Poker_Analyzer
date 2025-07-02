import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../services/template_undo_redo_service.dart';
import 'package:collection/collection.dart';
import '../../models/game_type.dart';
import '../../helpers/training_pack_storage.dart';
import '../../helpers/title_utils.dart';
import '../../models/v2/hand_data.dart';
import '../../models/v2/hero_position.dart';
import '../../models/saved_hand.dart';
import '../../models/action_entry.dart';
import 'training_pack_spot_editor_screen.dart';
import '../../widgets/v2/training_pack_spot_preview_card.dart';
import '../../widgets/spot_viewer_dialog.dart';
import '../../services/training_session_service.dart';
import '../training_session_screen.dart';
import '../../helpers/training_pack_validator.dart';
import '../../widgets/common/ev_distribution_chart.dart';
import '../../widgets/ev_summary_card.dart';
import '../../theme/app_colors.dart';
import '../../services/room_hand_history_importer.dart';
import '../../services/push_fold_ev_service.dart';
import '../../services/pack_export_service.dart';
import '../../widgets/range_matrix_picker.dart';
import '../../services/evaluation_executor_service.dart';
import '../../services/pack_generator_service.dart';
import '../../services/training_pack_template_ui_service.dart';
import '../../helpers/hand_utils.dart';
import '../../services/training_pack_template_storage_service.dart';

enum SortBy { manual, title, evDesc, edited, autoEv }

TrainingPackSpot? _copiedSpot;
class UndoIntent extends Intent { const UndoIntent(); }
class RedoIntent extends Intent { const RedoIntent(); }

class TrainingPackTemplateEditorScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  final List<TrainingPackTemplate> templates;
  const TrainingPackTemplateEditorScreen({
    super.key,
    required this.template,
    required this.templates,
  });

  @override
  State<TrainingPackTemplateEditorScreen> createState() => _TrainingPackTemplateEditorScreenState();
}

class _TrainingPackTemplateEditorScreenState extends State<TrainingPackTemplateEditorScreen> {
  late final TextEditingController _descCtr;
  late final FocusNode _descFocus;
  late String _templateName;
  String _query = '';
  String? _tagFilter;
  late TextEditingController _searchCtrl;
  late TextEditingController _tagSearchCtrl;
  String _tagSearch = '';
  Set<String> _selectedTags = {};
  Set<String> _selectedSpotIds = {};
  bool get _isMultiSelect => _selectedSpotIds.isNotEmpty;
  SortBy _sortBy = SortBy.manual;
  bool _autoSortEv = false;
  bool _pinnedOnly = false;
  bool _heroPushOnly = false;
  bool _mistakeOnly = false;
  bool _changedOnly = false;
  bool _filtersShown = false;
  List<TrainingPackSpot>? _lastRemoved;
  static const _prefsAutoSortKey = 'auto_sort_ev';
  static const _prefsEvFilterKey = 'ev_filter';
  static const _prefsEvRangeKey = 'ev_range';
  static const _prefsTagFilterKey = 'tag_filter';
  static const _prefsQuickFilterKey = 'quick_filter';
  static const _prefsSortKey = 'sort_mode';
  static const _prefsScrollKey = 'tmpl_scroll';
  static const _prefsSortModeKey = 'templateSortMode';
  String _evFilter = 'all';
  RangeValues _evRange = const RangeValues(-5, 5);
  bool _evAsc = false;
  static const _quickFilters = [
    'BTN',
    'SB',
    'Hero push only',
    'Mistake spots'
  ];
  String? _quickFilter;
  final ScrollController _scrollCtrl = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};
  String? _highlightId;
  final GlobalKey _previewKey = GlobalKey();
  bool _summaryIcm = false;
  bool _evaluatingAll = false;
  bool _generatingAll = false;
  bool _generatingIcm = false;
  bool _cancelRequested = false;
  late final UndoRedoService _history;
  bool get _canUndo => _history.canUndo;
  bool get _canRedo => _history.canRedo;

  void _storeTagFilter() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsTagFilterKey, _tagFilter ?? '');
  }

  void _storeQuickFilter() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsQuickFilterKey, _quickFilter ?? '');
  }

  void _storeSort() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsSortKey, _sortBy.name);
  }

  void _storeScroll() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_prefsScrollKey, _scrollCtrl.offset);
  }

  Set<String> _templateRange() {
    final set = <String>{};
    for (final s in widget.template.spots) {
      final hand = handCode(s.hand.heroCards);
      if (hand != null) set.add(hand);
    }
    return set;
  }

  List<TrainingPackSpot> _visibleSpots() {
    final changed = _changedOnly
        ? _history.history.map((e) => e.id).toSet()
        : null;
    return widget.template.spots.where((s) {
      if (_pinnedOnly && !s.pinned) return false;
      final res = s.evalResult;
      if (_evFilter == 'ok' && !(res != null && res.correct)) return false;
      if (_evFilter == 'error' && !(res != null && !res.correct)) return false;
      if (_evFilter == 'empty' && res != null) return false;
      if (_mistakeOnly && !(res != null && !res.correct)) return false;
      if (_quickFilter == 'BTN' && s.hand.position != HeroPosition.btn) {
        return false;
      }
      if (_quickFilter == 'SB' && s.hand.position != HeroPosition.sb) {
        return false;
      }
      if (_quickFilter == 'Hero push only') {
        final acts = s.hand.actions[0] ?? [];
        final push = acts.any(
            (a) => a.playerIndex == s.hand.heroIndex && a.action == 'push');
        if (!push) return false;
      }
      if (_quickFilter == 'Mistake spots' && !(res != null && !res.correct)) {
        return false;
      }
      if (_heroPushOnly) {
        final acts = s.hand.actions[0] ?? [];
        final hero = acts.where((a) => a.playerIndex == s.hand.heroIndex);
        final set = {for (final a in hero) a.action};
        if (!(set.length == 1 && set.contains('push'))) return false;
      }
      if (_selectedTags.isNotEmpty && !s.tags.any(_selectedTags.contains)) {
        return false;
      }
      if (_tagFilter != null &&
          !s.tags.any((t) => t.toLowerCase() == _tagFilter)) {
        return false;
      }
      final ev = s.heroEv;
      if (ev != null && (ev < _evRange.start || ev > _evRange.end)) {
        return false;
      }
      if (changed != null && !changed.contains(s.id)) return false;
      if (_query.isEmpty) return true;
      return s.title.toLowerCase().contains(_query) ||
          s.tags.any((t) => t.toLowerCase().contains(_query));
    }).toList();
  }

  void _focusSpot(String id) {
    final key = _itemKeys[id];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      setState(() => _highlightId = id);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _highlightId == id) {
          setState(() => _highlightId = null);
        }
      });
    }
  }

  void _recordSnapshot() => _history.record(widget.template.spots);

  void _log(String action, TrainingPackSpot spot) {
    _history.log(action, spot.title, spot.id);
    final key = _itemKeys[spot.id];
    if (key?.currentContext != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _focusSpot(spot.id));
    }
  }

  Future<void> _openEditor(TrainingPackSpot spot) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainingPackSpotEditorScreen(spot: spot)),
    );
    setState(() {
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    setState(() => _log('Edited', spot));
  }

  Future<void> _persist() async {
    widget.template.recountCoverage();
    await TrainingPackStorage.save(widget.templates);
  }

  void _saveOnly() {
    TrainingPackStorage.save(widget.templates);
  }

  Future<void> _undo() async {
    final snap = _history.undo(widget.template.spots);
    if (snap == null) return;
    setState(() {
      widget.template.spots
        ..clear()
        ..addAll(snap);
    });
    await _persist();
  }

  Future<void> _redo() async {
    final snap = _history.redo(widget.template.spots);
    if (snap == null) return;
    setState(() {
      widget.template.spots
        ..clear()
        ..addAll(snap);
    });
    await _persist();
  }

  void _jumpToLastChange() {
    final entry = _history.history.isEmpty ? null : _history.history.first;
    if (entry == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No recent changes')));
      return;
    }
    final spot = widget.template.spots
        .firstWhereOrNull((s) => s.id == entry.id || s.title == entry.title);
    if (spot == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No recent changes')));
      return;
    }
    _focusSpot(spot.id);
  }

  Future<void> _addSpot() async {
    _recordSnapshot();
    final spot = TrainingPackSpot(
      id: const Uuid().v4(),
      title: normalizeSpotTitle('New spot'),
    );
    setState(() => widget.template.spots.add(spot));
    await _persist();
    setState(() => _log('Added', spot));
    await _openEditor(spot);
  }

  Future<void> _generateSpot() async {
    _recordSnapshot();
    final spot = TrainingPackSpot(
      id: const Uuid().v4(),
      title: 'New Spot',
    );
    setState(() => widget.template.spots.add(spot));
    await _persist();
    setState(() => _log('Added', spot));
    await _openEditor(spot);
  }

  Future<void> _generateSpots() async {
    _recordSnapshot();
    final service = TrainingPackTemplateUiService();
    final generated =
        await service.generateSpotsWithProgress(context, widget.template);
    if (!mounted) return;
    setState(() {
      widget.template.spots.addAll(generated);
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    if (generated.isNotEmpty) {
      setState(() => _history.log('Added', '${generated.length} spots', ''));
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Generated ${generated.length} spots')));
  }

  Future<void> _generateMissingSpots() async {
    final service = TrainingPackTemplateUiService();
    final missing =
        await service.generateMissingSpotsWithProgress(context, widget.template);
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All spots already present 🎉')));
      return;
    }
    setState(() {
      widget.template.spots.addAll(missing);
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    setState(() => _history.log('Added', '${missing.length} spots', ''));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added ${missing.length} spots')));
  }

  Future<void> _pasteSpot() async {
    final c = TextEditingController();
    final input = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paste Spot'),
        content: TextField(controller: c, maxLines: null, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    _recordSnapshot();
    if (input == null || input.trim().isEmpty) return;
    try {
      final json = jsonDecode(input);
      if (json is! Map<String, dynamic>) throw const FormatException();
      final spot = TrainingPackSpot.fromJson(json)
          .copyWith(id: const Uuid().v4(), editedAt: DateTime.now());
      setState(() {
        widget.template.spots.add(spot);
        if (_autoSortEv) _sortSpots();
      });
      await _persist();
      setState(() => _log('Added', spot));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Spot pasted')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid JSON')));
      }
    }
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
    final stacks = <String, double>{
      for (int i = 0; i < hand.numberOfPlayers; i++) '$i': (hand.stackSizes[i] ?? 0).toDouble()
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
    );
  }

  Future<void> _pasteHandHistory() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paste Hand History'),
        content: TextField(controller: c, maxLines: null, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    _recordSnapshot();
    if (text == null || text.trim().isEmpty) return;
    final importer = await RoomHandHistoryImporter.create();
    final hands = importer.parse(text);
    if (hands.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid hand')));
      }
      return;
    }
    final spot = _spotFromHand(hands.first);
    setState(() {
      widget.template.spots.add(spot);
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    setState(() => _log('Added', spot));
  }

  Future<void> _addPackTag() async {
    final allTags = widget.templates.expand((t) => t.tags).toSet().toList();
    final c = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tag'),
        content: Autocomplete<String>(
          optionsBuilder: (v) {
            final input = v.text.toLowerCase();
            if (input.isEmpty) return allTags;
            return allTags.where((e) => e.toLowerCase().contains(input));
          },
          onSelected: (s) => Navigator.pop(context, s),
          fieldViewBuilder: (context, controller, focusNode, _) {
            controller.text = c.text;
            controller.selection = c.selection;
            controller.addListener(() {
              if (c.text != controller.text) c.value = controller.value;
            });
            c.addListener(() {
              if (controller.text != c.text) controller.value = c.value;
            });
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    if (tag == null || tag.isEmpty) return;
    setState(() => widget.template.tags.add(tag));
    _persist();
  }

  void _saveDesc() {
    setState(() => widget.template.description = _descCtr.text.trim());
    _persist();
  }

  Future<void> _renameTemplate() async {
    final ctrl = TextEditingController(text: _templateName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename template'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
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
    );
    if (ok == true) {
      final name = ctrl.text.trim();
      if (name.isNotEmpty) {
        setState(() {
          _templateName = name;
          widget.template.name = name;
        });
        final service = context.read<TrainingPackTemplateStorageService>();
        await service.saveAll();
        await _persist();
      }
    }
    ctrl.dispose();
  }

  @override
  void initState() {
    super.initState();
    _templateName = widget.template.name;
    _descCtr = TextEditingController(text: widget.template.description);
    _descFocus = FocusNode();
    _descFocus.addListener(() {
      if (!_descFocus.hasFocus) _saveDesc();
    });
    _searchCtrl = TextEditingController();
    _tagSearchCtrl = TextEditingController();
    _history = UndoRedoService(eventsLimit: 50);
    _history.record(widget.template.spots);
    _scrollCtrl.addListener(_storeScroll);
    SharedPreferences.getInstance().then((prefs) {
      final auto = prefs.getBool(_prefsAutoSortKey) ?? false;
      final filter = prefs.getString(_prefsEvFilterKey) ?? 'all';
      final rangeStr = prefs.getString(_prefsEvRangeKey);
      final tag = prefs.getString(_prefsTagFilterKey);
      final quick = prefs.getString(_prefsQuickFilterKey);
      final sortStr = prefs.getString(_prefsSortKey);
      final sortMode = prefs.getString(_prefsSortModeKey);
      final offset = prefs.getDouble(_prefsScrollKey) ?? 0;
      var range = const RangeValues(-5, 5);
      if (rangeStr != null) {
        final parts = rangeStr.split(',');
        if (parts.length == 2) {
          final start = double.tryParse(parts[0]);
          final end = double.tryParse(parts[1]);
          if (start != null && end != null) {
            range = RangeValues(start, end);
          }
        }
      }
      SortBy sort = SortBy.manual;
      if (sortStr != null) {
        for (final v in SortBy.values) {
          if (v.name == sortStr) {
            sort = v;
            break;
          }
        }
      }
      if (sortMode != null) _evAsc = sortMode == 'asc';
      if (mounted) {
        setState(() {
          _autoSortEv = auto;
          _evFilter = filter;
          _evRange = range;
          _tagFilter = tag?.isEmpty ?? true ? null : tag;
          _quickFilter = quick?.isEmpty ?? true ? null : quick;
          _sortBy = sort;
          if (sortMode != null) _sortSpots();
          });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(offset);
        });
      }
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
    _storeScroll();
    _descFocus.dispose();
    _descCtr.dispose();
    _searchCtrl.dispose();
    _tagSearchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _save() {
    _saveDesc();
    if (widget.template.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    _persist();
    Navigator.pop(context);
  }

  Future<void> _export() async {
    try {
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final safeName = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}/$safeName.json');
      await file.writeAsString(jsonEncode(widget.template.toJson()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл сохранён: ${file.path}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось экспортировать файл')),
        );
      }
    }
  }

  Future<String?> _exportBundle({bool notify = true}) async {
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/template_bundle');
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create();
      final jsonFile = File('${dir.path}/template.json');
      await jsonFile.writeAsString(jsonEncode(widget.template.toJson()));
      for (int i = 0; i < widget.template.spots.length; i++) {
        final spot = widget.template.spots[i];
        final key = _itemKeys[spot.id];
        final boundary = key?.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) continue;
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = data?.buffer.asUint8List();
        if (bytes == null) continue;
        final imgFile = File('${dir.path}/spot_$i.png');
        await imgFile.writeAsBytes(bytes);
      }
      final archive = Archive();
      for (final file in dir.listSync().whereType<File>()) {
        final data = await file.readAsBytes();
        final name = file.path.split(Platform.pathSeparator).last;
        archive.addFile(ArchiveFile(name, data.length, data));
      }
      final bytes = ZipEncoder().encode(archive);
      if (bytes == null) throw Exception('zip');
      final downloads = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final zipFile = File('${downloads.path}/$safe.zip');
      await zipFile.writeAsBytes(bytes, flush: true);
      if (!mounted) return zipFile.path;
      if (notify) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(child: Text('Bundle saved: ${zipFile.path}')),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: zipFile.path));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Path copied')),
                    );
                  },
                  child: const Text('Copy'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await Share.shareXFiles([XFile(zipFile.path)]);
                    } catch (_) {}
                  },
                  child: const Text('📤 Share Bundle'),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(zipFile.path),
            ),
          ),
        );
      }
      return zipFile.path;
    } catch (_) {
      if (mounted && notify) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось создать пакет')),
        );
      }
      return null;
    }
  }

  Future<void> _shareBundle() async {
    final path = await _exportBundle(notify: false);
    if (path == null || !mounted) return;
    try {
      await Share.shareXFiles([XFile(path)]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bundle shared')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось поделиться пакетом')),
      );
    }
  }

  Future<void> _exportCsv() async {
    try {
      final file = await PackExportService.exportToCsv(widget.template);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('CSV exported')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _previewBundle() async {
    final path = await _exportBundle(notify: false);
    if (path == null || !mounted) return;
    try {
      final data = await File(path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(data);
      final files = [for (final f in archive.files) if (f.isFile) f.name];
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Bundle Preview'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (_, i) => ListTile(title: Text(files[i])),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка предпросмотра пакета')),
        );
      }
    }
  }

  Future<Uint8List?> _capturePreview() async {
    final entry = OverlayEntry(
      builder: (_) => Center(
        child: Opacity(
          opacity: 0,
          child: RepaintBoundary(
            key: _previewKey,
            child: _TemplatePreviewCard(template: widget.template),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    await Future.delayed(const Duration(milliseconds: 50));
    final boundary =
        _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    Uint8List? bytes;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      bytes = data?.buffer.asUint8List();
    }
    entry.remove();
    return bytes;
  }

  Future<void> _exportPreview() async {
    final bytes = await _capturePreview();
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось создать превью')),
        );
      }
      return;
    }
    try {
      final dir =
          await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}/$safe.png');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(child: Text('Preview saved: ${file.path}')),
              TextButton(
                onPressed: () async {
                  try {
                    await Share.shareXFiles([XFile(file.path)]);
                  } catch (_) {}
                },
                child: const Text('📤 Share'),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить превью')),
        );
      }
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'zip'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    Uint8List? data = file.bytes;
    final path = file.path;
    if (data == null && path != null) data = await File(path).readAsBytes();
    _recordSnapshot();
    try {
      TrainingPackTemplate tpl;
      if (file.extension?.toLowerCase() == 'zip') {
        final tmp = await getTemporaryDirectory();
        final dir = Directory('${tmp.path}/tpl_import_${DateTime.now().microsecondsSinceEpoch}');
        if (await dir.exists()) await dir.delete(recursive: true);
        await dir.create();
        final archive = ZipDecoder().decodeBytes(data);
        for (final f in archive.files) {
          if (f.isFile && !f.name.endsWith('.png')) {
            final out = File('${dir.path}/${f.name}');
            await out.create(recursive: true);
            await out.writeAsBytes(f.content as List<int>);
          }
        }
        final tplFile = File('${dir.path}/template.json');
        final jsonStr = await tplFile.readAsString();
        final json = jsonDecode(jsonStr);
        if (json is! Map<String, dynamic>) throw const FormatException();
        tpl = TrainingPackTemplate.fromJson(json);
        await dir.delete(recursive: true);
      } else {
        final json = jsonDecode(utf8.decode(data));
        if (json is! Map<String, dynamic>) throw const FormatException();
        tpl = TrainingPackTemplate.fromJson(json);
      }
      setState(() {
        widget.template.spots
          ..clear()
          ..addAll(tpl.spots);
        if (_autoSortEv) _sortSpots();
      });
      _persist();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Импортировано спотов: ${tpl.spots.length}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось импортировать файл')),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove all spots from this template?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok ?? false) {
      _recordSnapshot();
      setState(() => widget.template.spots.clear());
      _persist();
      setState(() => _history.log('Deleted', 'all spots', ''));
    }
  }

  void _showSummary() {
    final spots = widget.template.spots;
    final total = spots.length;
    final tags = spots.expand((s) => s.tags).toList();
    final heroEvs = [for (final s in spots) if (s.heroEv != null) s.heroEv!];
    final uniqueTags = tags.toSet();
    final counts = <String, int>{};
    for (final t in tags) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spots: $total'),
              Text('Tags: ${uniqueTags.length}'),
              const SizedBox(height: 8),
              for (final e in entries) Text('${e.key}: ${e.value}'),
              if (heroEvs.isNotEmpty) EvDistributionChart(evs: heroEvs),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _validateTemplate() {
    final issues = validateTrainingPackTemplate(widget.template);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Validation'),
        content: issues.isEmpty
            ? const Text('No issues found')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final e in issues) Text(e)],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  void _regenerateEv() {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
            a.ev = computePushEV(
              heroBbStack: stack,
              bbCount: spot.hand.playerCount - 1,
              heroHand: hand,
              anteBb: 0,
            );
            break;
          }
        }
      }
    });
    _persist();
  }

  void _regenerateIcm() {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        final stacks = [
          for (var i = 0; i < spot.hand.playerCount; i++)
            spot.hand.stacks['$i']?.round() ?? 0
        ];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
            final chipEv = a.ev ?? computePushEV(
              heroBbStack: stack,
              bbCount: spot.hand.playerCount - 1,
              heroHand: hand,
              anteBb: 0,
            );
            a.icmEv = computeIcmPushEV(
              chipStacksBb: stacks,
              heroIndex: hero,
              heroHand: hand,
              chipPushEv: chipEv,
            );
            break;
          }
        }
      }
    });
    _persist();
  }

  void _recalculateAll() {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        final stacks = [
          for (var i = 0; i < spot.hand.playerCount; i++)
            spot.hand.stacks['$i']?.round() ?? 0
        ];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
            a.ev = computePushEV(
              heroBbStack: stack,
              bbCount: spot.hand.playerCount - 1,
              heroHand: hand,
              anteBb: 0,
            );
            a.icmEv = computeIcmPushEV(
              chipStacksBb: stacks,
              heroIndex: hero,
              heroHand: hand,
              chipPushEv: a.ev!,
            );
            break;
          }
        }
      }
    });
    _persist();
  }

  void _tagAllMistakes() {
    int count = 0;
    setState(() {
      for (final s in widget.template.spots) {
        final r = s.evalResult;
        if (r != null && !r.correct && !s.tags.contains('Mistake')) {
          s.tags.add('Mistake');
          _history.log('Tagged', s.title, s.id);
          count++;
        }
      }
    });
    _persist();
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tagged $count spot(s)')),
      );
    }
  }

  Future<void> _evaluateAllSpots() async {
    setState(() => _evaluatingAll = true);
    final spots = widget.template.spots;
    final total = spots.length;
    int done = 0;
    int errors = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (final spot in spots) {
                  try {
                    final res = await context
                        .read<EvaluationExecutorService>()
                        .evaluate(spot);
                    if (mounted) {
                      setState(() => spot.evalResult = res);
                      await _persist();
                    }
                  } catch (e) {
                    errors++;
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Spot "${spot.title}" failed: $e'),
                        ),
                      );
                    }
                  }
                  done++;
                  if (mounted) setDialog(() {});
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: done / total),
                  const SizedBox(height: 12),
                  Text(
                    'Evaluated $done / $total',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _evaluatingAll = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Evaluated $total spots (${total - errors} OK, $errors errors)'),
      ),
    );
  }

  Future<void> _generateAllEv() async {
    setState(() => _generatingAll = true);
    final spots = _visibleSpots();
    final total = spots.length;
    int done = 0;
    final failed = <String>[];
    _cancelRequested = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (var i = 0; i < spots.length; i++) {
                  if (_cancelRequested) break;
                  final s = spots[i];
                  try {
                    if (s.heroEv == null) {
                      await const PushFoldEvService().evaluate(s);
                      widget.template.meta['evCovered'] =
                          (widget.template.meta['evCovered'] ?? 0) + 1;
                      if (!mounted) return;
                      setState(() {
                        if (_autoSortEv) _sortSpots();
                      });
                    }
                  } catch (_) {
                    failed.add('${i + 1}. ${s.title.isEmpty ? 'Spot' : s.title}');
                  }
                  done++;
                  if (mounted) setDialog(() {});
                  await Future.delayed(Duration.zero);
                }
                await _persist();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return AlertDialog(
              content: Text('Generated $done of $total EV…'),
              actions: [
                TextButton(
                  onPressed: () => _cancelRequested = true,
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _generatingAll = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Generated $total spots (${total - failed.length} OK, ${failed.length} errors)'),
      ),
    );
    if (failed.isNotEmpty) {
      await _showGenerationErrors(failed, 'EV');
    }
  }

  Future<void> _generateAllIcm() async {
    setState(() => _generatingIcm = true);
    final spots = _visibleSpots();
    final total = spots.length;
    int done = 0;
    final failed = <String>[];
    _cancelRequested = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (var i = 0; i < spots.length; i++) {
                  if (_cancelRequested) break;
                  final s = spots[i];
                  try {
                    if (s.heroIcmEv == null) {
                      await const PushFoldEvService().evaluateIcm(s);
                      widget.template.meta['icmCovered'] =
                          (widget.template.meta['icmCovered'] ?? 0) + 1;
                      if (!mounted) return;
                      setState(() {
                        if (_autoSortEv) _sortSpots();
                      });
                    }
                  } catch (_) {
                    failed.add('${i + 1}. ${s.title.isEmpty ? 'Spot' : s.title}');
                  }
                  done++;
                  if (mounted) setDialog(() {});
                  await Future.delayed(Duration.zero);
                }
                await _persist();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return AlertDialog(
              content: Text('Generated $done of $total ICM…'),
              actions: [
                TextButton(
                  onPressed: () => _cancelRequested = true,
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _generatingIcm = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Generated $total spots (${total - failed.length} OK, ${failed.length} errors)'),
      ),
    );
    if (failed.isNotEmpty) {
      await _showGenerationErrors(failed, 'ICM');
    }
  }

  Future<void> _showGenerationErrors(List<String> failed, String type) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$type Generation Errors (${failed.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: failed.length,
            itemBuilder: (_, i) => ListTile(title: Text(failed[i])),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: failed.join('\n')));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkAddTag() async {
    final allTags = widget.templates.expand((t) => t.tags).toSet().toList();
    final c = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tag'),
        content: Autocomplete<String>(
          optionsBuilder: (v) {
            final input = v.text.toLowerCase();
            if (input.isEmpty) return allTags;
            return allTags.where((e) => e.toLowerCase().contains(input));
          },
          onSelected: (s) => Navigator.pop(context, s),
          fieldViewBuilder: (context, controller, focusNode, _) {
            controller.text = c.text;
            controller.selection = c.selection;
            controller.addListener(() {
              if (c.text != controller.text) c.value = controller.value;
            });
            c.addListener(() {
              if (controller.text != c.text) controller.value = c.value;
            });
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    if (tag == null || tag.isEmpty) return;
    setState(() {
      for (final id in _selectedSpotIds) {
        final s = widget.template.spots.firstWhere((e) => e.id == id);
        if (!s.tags.contains(tag)) {
          s.tags.add(tag);
          _history.log('Tagged', s.title, s.id);
        }
      }
    });
    await _persist();
    setState(() => _selectedSpotIds.clear());
  }

  Future<void> _bulkRemoveTag() async {
    final spots = [for (final s in widget.template.spots) if (_selectedSpotIds.contains(s.id)) s];
    if (spots.isEmpty) return;
    Set<String> tags = Set.from(spots.first.tags);
    for (final s in spots.skip(1)) {
      tags = tags.intersection(s.tags.toSet());
    }
    String? selected = tags.isNotEmpty ? tags.first : null;
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Remove Tag'),
          content: DropdownButton<String>(
            value: selected,
            items: [for (final t in tags) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setStateDialog(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, selected), child: const Text('OK')),
          ],
        ),
      ),
    );
    if (tag == null || tag.isEmpty) return;
    setState(() {
      for (final id in _selectedSpotIds) {
        final s = widget.template.spots.firstWhere((e) => e.id == id);
        if (s.tags.remove(tag)) {
          _history.log('Untagged', s.title, s.id);
        }
      }
    });
    await _persist();
    setState(() => _selectedSpotIds.clear());
  }

  Future<void> _bulkMoveToTag(String tag) async {
    setState(() {
      for (final id in _selectedSpotIds) {
        final s = widget.template.spots.firstWhere((e) => e.id == id);
        s.tags
          ..clear();
        if (tag.isNotEmpty) {
          s.tags.add(tag);
          _history.log('Tagged', s.title, s.id);
        } else {
          _history.log('Untagged', s.title, s.id);
        }
      }
    });
    await _persist();
    setState(() => _selectedSpotIds.clear());
  }

  Future<void> _bulkTogglePin() async {
    final spots = [for (final s in widget.template.spots) if (_selectedSpotIds.contains(s.id)) s];
    if (spots.isEmpty) return;
    final newState = spots.any((s) => !s.pinned);
    setState(() {
      for (final s in spots) {
        s.pinned = newState;
      }
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    setState(() => _selectedSpotIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newState ? 'Pinned' : 'Unpinned'} ${spots.length} spot(s)')),
    );
  }

  Future<void> _bulkTransfer(bool move) async {
    final targets = [for (final t in widget.templates) if (t.id != widget.template.id) t];
    if (targets.isEmpty) return;
    TrainingPackTemplate? selected = targets.first;
    final dest = await showDialog<TrainingPackTemplate>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(move ? 'Move to Pack' : 'Copy to Pack'),
          content: DropdownButton<TrainingPackTemplate>(
            value: selected,
            isExpanded: true,
            items: [for (final t in targets) DropdownMenuItem(value: t, child: Text(t.name))],
            onChanged: (v) => setStateDialog(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, selected), child: const Text('OK')),
          ],
        ),
      ),
    );
    if (dest == null) return;
    final spots = [for (final s in widget.template.spots) if (_selectedSpotIds.contains(s.id)) s];
    if (spots.isEmpty) return;
    final copies = [
      for (final s in spots)
        s.copyWith(
          id: const Uuid().v4(),
          editedAt: DateTime.now(),
          hand: HandData.fromJson(s.hand.toJson()),
          tags: List.from(s.tags),
        )
    ];
    setState(() {
      dest.spots.addAll(copies);
      if (move) {
        widget.template.spots.removeWhere((s) => _selectedSpotIds.contains(s.id));
        if (_autoSortEv) _sortSpots();
      }
    });
    await _persist();
    setState(() => _selectedSpotIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${move ? 'Moved' : 'Copied'} ${copies.length} spot(s)')),
    );
  }

  Future<void> _bulkMove() => _bulkTransfer(true);
  Future<void> _bulkCopy() => _bulkTransfer(false);

  void _newPackFromSelection() {
    final spots = [
      for (final s in widget.template.spots)
        if (_selectedSpotIds.contains(s.id))
          s.copyWith(
            id: const Uuid().v4(),
            editedAt: DateTime.now(),
            hand: HandData.fromJson(s.hand.toJson()),
            tags: List.from(s.tags),
          )
    ];
    if (spots.isEmpty) return;
    final tpl = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: '${widget.template.name} Subset',
      gameType: widget.template.gameType,
      spots: spots,
      createdAt: DateTime.now(),
    );
    final index = widget.templates.indexOf(widget.template);
    setState(() {
      widget.templates.insert(index + 1, tpl);
      _selectedSpotIds.clear();
    });
    _persist();
  }

  Future<void> _bulkDelete() async {
    final count = _selectedSpotIds.length;
    if (count == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $count spots?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok ?? false) {
      _recordSnapshot();
      _lastRemoved = widget.template.spots.where((s) => _selectedSpotIds.contains(s.id)).toList();
      setState(() {
        widget.template.spots.removeWhere((s) => _selectedSpotIds.contains(s.id));
        _selectedSpotIds.clear();
        if (_autoSortEv) _sortSpots();
      });
      _persist();
      setState(() =>
          _history.log('Deleted', '${_lastRemoved!.length} spots', ''));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${_lastRemoved!.length} spot(s)'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                widget.template.spots.addAll(_lastRemoved!);
                if (_autoSortEv) _sortSpots();
              });
              _persist();
            },
          ),
        ),
      );
    }
  }

  void _selectAll() {
    setState(() {
      _selectedSpotIds
        ..clear()
        ..addAll(widget.template.spots.map((e) => e.id));
    });
  }

  void _invertSelection() {
    final all = widget.template.spots.map((e) => e.id).toSet();
    setState(() => _selectedSpotIds = all.difference(_selectedSpotIds));
  }

  void _duplicateSpot(TrainingPackSpot spot) {
    _recordSnapshot();
    final i = widget.template.spots.indexOf(spot);
    if (i == -1) return;
    final copy = spot.copyWith(
      id: const Uuid().v4(),
      editedAt: DateTime.now(),
      hand: HandData.fromJson(spot.hand.toJson()),
      tags: List.from(spot.tags),
    );
    setState(() => widget.template.spots.insert(i + 1, copy));
    _persist();
    setState(() => _log('Added', copy));
  }

  Future<void> _renameTag() async {
    final tags = widget.template.spots.expand((s) => s.tags).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    if (tags.isEmpty) return;
    String? selected = tags.first;
    final searchCtr = TextEditingController();
    final newCtr = TextEditingController();
    final result = await showDialog<List<String>?>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final filtered = tags
              .where((t) => t
                  .toLowerCase()
                  .contains(searchCtr.text.toLowerCase()))
              .toList();
          if (!filtered.contains(selected)) selected = filtered.isEmpty ? null : filtered.first;
          return AlertDialog(
            title: const Text('Rename Tag'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtr,
                  decoration: const InputDecoration(labelText: 'Search'),
                  onChanged: (_) => setStateDialog(() {}),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selected,
                  isExpanded: true,
                  items: [for (final t in filtered) DropdownMenuItem(value: t, child: Text(t))],
                  onChanged: (v) => setStateDialog(() => selected = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newCtr,
                  decoration: const InputDecoration(labelText: 'New tag'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, [selected ?? '', newCtr.text.trim()]),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
    searchCtr.dispose();
    newCtr.dispose();
    if (result == null) return;
    final oldTag = result[0];
    final newTag = result[1];
    if (oldTag.isEmpty || newTag.isEmpty || oldTag == newTag) return;
    setState(() {
      for (final s in widget.template.spots) {
        if (s.tags.remove(oldTag) && !s.tags.contains(newTag)) {
          s.tags.add(newTag);
        } else {
          while (s.tags.remove(oldTag)) {}
          if (!s.tags.contains(newTag)) s.tags.add(newTag);
        }
      }
    });
    await _persist();
    setState(() {});
  }

  Future<void> _manageTags() async {
    final tags = <String>{
      ...widget.template.tags,
      ...widget.template.spots.expand((s) => s.tags),
    }.toList()
      ..sort((a, b) => a.compareTo(b));
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          void rename(String oldTag, String newTag) {
            if (newTag.isEmpty || oldTag == newTag) return;
            setState(() {
              for (final s in widget.template.spots) {
                for (var i = 0; i < s.tags.length; i++) {
                  if (s.tags[i] == oldTag) s.tags[i] = newTag;
                }
                s.tags = s.tags.toSet().toList();
              }
              widget.template.tags.removeWhere((t) => t == oldTag);
              if (!widget.template.tags.contains(newTag)) {
                widget.template.tags.add(newTag);
              }
            });
            _persist();
            setStateDialog(() {
              final i = tags.indexOf(oldTag);
              if (i != -1) tags[i] = newTag;
            });
          }

          void remove(String tag) {
            setState(() {
              widget.template.tags.removeWhere((t) => t == tag);
              for (final s in widget.template.spots) {
                s.tags.removeWhere((t) => t == tag);
              }
            });
            _persist();
            setStateDialog(() => tags.remove(tag));
          }

          return AlertDialog(
            title: const Text('Manage Tags'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final tag in tags)
                    _ManageTagTile(
                      key: ValueKey(tag),
                      tag: tag,
                      onRename: (v) => rename(tag, v),
                      onDelete: () => remove(tag),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  double _spotEv(TrainingPackSpot s) {
    final acts = s.hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == s.hand.heroIndex) return a.ev ?? double.negativeInfinity;
    }
    return double.negativeInfinity;
  }

  void _sortSpots() {
    final pinned = widget.template.spots.where((s) => s.pinned).toList();
    final others = widget.template.spots.where((s) => !s.pinned).toList();
    if (_evAsc) {
      others.sort((a, b) => _spotEv(a).compareTo(_spotEv(b)));
    } else {
      others.sort((a, b) => _spotEv(b).compareTo(_spotEv(a)));
    }
    widget.template.spots
      ..clear()
      ..addAll(pinned)
      ..addAll(others);
  }

  Future<void> _toggleEvSort() async {
    setState(() {
      _evAsc = !_evAsc;
      _sortSpots();
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsSortModeKey, _evAsc ? 'asc' : 'desc');
  }

  void _showFilters() {
    final tags = widget.template.spots.expand((s) => s.tags).toSet();
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Pinned Only'),
                value: _pinnedOnly,
                onChanged: (v) => set(() {
                  this.setState(() => _pinnedOnly = v);
                }),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in tags)
                    FilterChip(
                      label: Text(tag),
                      selected: _selectedTags.contains(tag),
                      onSelected: (v) => set(() {
                        this.setState(() {
                          v ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                        });
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _evFilter,
                decoration: const InputDecoration(labelText: 'EV'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'ok', child: Text('OK')),
                  DropdownMenuItem(value: 'error', child: Text('Errors')),
                  DropdownMenuItem(value: 'empty', child: Text('Empty')),
                ],
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();
                  final val = v ?? 'all';
                  set(() => _evFilter = val);
                  this.setState(() {});
                  prefs.setString(_prefsEvFilterKey, val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTemplateSettings() async {
    final heroCtr = TextEditingController(text: widget.template.heroBbStack.toString());
    final stacksCtr = TextEditingController(text: widget.template.playerStacksBb.join(','));
    HeroPosition pos = widget.template.heroPos;
    final countCtr = TextEditingController(text: widget.template.spotCount.toString());
    double bbCall = widget.template.bbCallPct.toDouble();
    final anteCtr = TextEditingController(text: widget.template.anteBb.toString());
    String _rangeStr = widget.template.heroRange?.join(' ') ?? '';
    String rangeMode = 'simple';
    final rangeCtr = TextEditingController(text: _rangeStr);
    bool rangeErr = false;
    final formKey = GlobalKey<FormState>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, set) {
            final narrow = MediaQuery.of(context).size.width < 500;
            final fields = [
              TextFormField(
                controller: heroCtr,
                decoration: const InputDecoration(labelText: 'Hero BB Stack'),
                keyboardType: TextInputType.number,
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? '' : null,
              ),
              TextFormField(
                controller: stacksCtr,
                decoration: const InputDecoration(labelText: 'Player Stacks BB'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '';
                  for (final s in v.split(RegExp('[,/]'))) {
                    if (s.trim().isEmpty) continue;
                    if ((int.tryParse(s.trim()) ?? 0) < 1) return '';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<HeroPosition>(
                value: pos,
                decoration: const InputDecoration(labelText: 'Hero Position'),
                items: const [
                  DropdownMenuItem(value: HeroPosition.sb, child: Text('SB')),
                  DropdownMenuItem(value: HeroPosition.bb, child: Text('BB')),
                  DropdownMenuItem(value: HeroPosition.btn, child: Text('BTN')),
                  DropdownMenuItem(value: HeroPosition.co, child: Text('CO')),
                  DropdownMenuItem(value: HeroPosition.mp, child: Text('MP')),
                  DropdownMenuItem(value: HeroPosition.utg, child: Text('UTG')),
                ],
                onChanged: (v) => set(() => pos = v ?? HeroPosition.sb),
              ),
              TextFormField(
                controller: countCtr,
                decoration: const InputDecoration(labelText: 'Spot Count'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '') ?? 0;
                  return n < 1 || n > 169 ? '' : null;
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BB call ${bbCall.round()}%'),
                  Slider(
                    value: bbCall,
                    min: 0,
                    max: 100,
                    onChanged: (v) => set(() => bbCall = v),
                  ),
                ],
              ),
              TextFormField(
                controller: anteCtr,
                decoration: const InputDecoration(labelText: 'Ante BB'),
                keyboardType: TextInputType.number,
                validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0 ? '' : null,
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: rangeMode,
                    items: const [
                      DropdownMenuItem(value: 'simple', child: Text('Simple')),
                      DropdownMenuItem(value: 'matrix', child: Text('Matrix')),
                    ],
                    onChanged: (v) => set(() => rangeMode = v ?? 'simple'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: rangeMode == 'simple'
                        ? TextFormField(
                            controller: rangeCtr,
                            decoration: InputDecoration(
                              labelText: 'Hero Range',
                              errorText: rangeErr ? '' : null,
                            ),
                            onChanged: (v) => set(() {
                              _rangeStr = v;
                              rangeErr = v.trim().isNotEmpty &&
                                  PackGeneratorService.parseRangeString(v).isEmpty;
                            }),
                          )
                        : GestureDetector(
                            onTap: () async {
                              final init = PackGeneratorService
                                  .parseRangeString(_rangeStr)
                                  .toSet();
                              final res = await Navigator.push<Set<String>>(
                                context,
                                MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (_) => _MatrixPickerPage(initial: init),
                                ),
                              );
                              if (res != null) set(() {
                                _rangeStr = PackGeneratorService.serializeRange(res);
                                rangeCtr.text = _rangeStr;
                                rangeErr = _rangeStr.trim().isNotEmpty &&
                                    PackGeneratorService.parseRangeString(_rangeStr).isEmpty;
                              });
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Hero Range',
                                errorText: rangeErr ? '' : null,
                              ),
                              child: Text(
                                _rangeStr.isEmpty ? 'All hands' : _rangeStr,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ];
            final content = narrow
                ? Column(mainAxisSize: MainAxisSize.min, children: fields)
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [for (final f in fields) SizedBox(width: 250, child: f)],
                  );
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    content,
                    const SizedBox(height: 16),
                    Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() != true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fix errors')));
                            return;
                          }
                          Navigator.pop(context, true);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    if (ok == true) {
      final hero = int.parse(heroCtr.text.trim());
      final list = [
        for (final s in stacksCtr.text.split(RegExp('[,/]')))
          if (s.trim().isNotEmpty) int.parse(s.trim())
      ];
      if (!list.contains(hero)) list.insert(0, hero);
      if (list.isEmpty) list.add(hero);
      final count = int.parse(countCtr.text.trim());
      final ante = int.parse(anteCtr.text.trim());
      final parsedSet = PackGeneratorService.parseRangeString(_rangeStr);
      setState(() {
        widget.template.heroBbStack = hero;
        widget.template.playerStacksBb = list;
        widget.template.heroPos = pos;
        widget.template.spotCount = count;
        widget.template.bbCallPct = bbCall.round();
        widget.template.anteBb = ante;
        widget.template.heroRange =
            parsedSet.isEmpty ? null : parsedSet.toList();
      });
      await _persist();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Template settings updated')));
      }
    }
    heroCtr.dispose();
    stacksCtr.dispose();
    countCtr.dispose();
    anteCtr.dispose();
    rangeCtr.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 400;
    final hasSpots = widget.template.spots.isNotEmpty;
    final shown = _visibleSpots();
    final chipVals = [for (final s in shown) if (s.heroEv != null) s.heroEv!];
    final icmVals = [for (final s in shown) if (s.heroIcmEv != null) s.heroIcmEv!];
    final totalSpots = widget.template.spots.length;
    final evCoverage = totalSpots == 0
        ? 0.0
        : widget.template.evCovered / totalSpots;
    final icmCoverage = totalSpots == 0
        ? 0.0
        : widget.template.icmCovered / totalSpots;
    final bothCoverage = evCoverage < icmCoverage ? evCoverage : icmCoverage;
    final heroEvsAll = [
      for (final s in widget.template.spots)
        if (s.heroEv != null) s.heroEv!
    ];
    final avgEv = heroEvsAll.isEmpty
        ? null
        : heroEvsAll.reduce((a, b) => a + b) / heroEvsAll.length;
    final tagCounts = <String, int>{};
    for (final t in widget.template.spots.expand((s) => s.tags)) {
      tagCounts[t] = (tagCounts[t] ?? 0) + 1;
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final summaryTags = [for (final e in topTags.take(3)) e.key];
    final range = _templateRange();
    final historyGroups = <String, List<ChangeEntry>>{};
    for (final e in _history.history) {
      final day = DateFormat.yMd().format(e.time);
      historyGroups.putIfAbsent(day, () => []).add(e);
    }
    List<TrainingPackSpot> sorted;
    if (_sortBy == SortBy.manual) {
      sorted = shown;
    } else {
      final pinned = [for (final s in shown) if (s.pinned) s];
      final rest = [for (final s in shown) if (!s.pinned) s];
      switch (_sortBy) {
        case SortBy.title:
          rest.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
        case SortBy.evDesc:
          double ev(TrainingPackSpot s) {
            final acts = s.hand.actions[0] ?? [];
            for (final a in acts) {
              if (a.playerIndex == s.hand.heroIndex) return a.ev ?? double.negativeInfinity;
            }
            return double.negativeInfinity;
          }
          rest.sort((a, b) => ev(b).compareTo(ev(a)));
          break;
        case SortBy.edited:
          rest.sort((a, b) => b.editedAt.compareTo(a.editedAt));
          break;
        case SortBy.autoEv:
          break;
        case SortBy.manual:
          break;
      }
      sorted = [...pinned, ...rest];
    }
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ): const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyY): const RedoIntent(),
      },
      child: Actions(
        actions: {
          UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => _undo()),
          RedoIntent: CallbackAction<RedoIntent>(onInvoke: (_) => _redo()),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
      appBar: AppBar(
        leading: _isMultiSelect
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedSpotIds.clear()),
              )
            : null,
        title: _isMultiSelect
            ? Text('${_selectedSpotIds.length} selected')
            : GestureDetector(
                onTap: _renameTemplate,
                child: Text(_templateName),
              ),
        actions: [
          DropdownButton<GameType>(
            value: widget.template.gameType,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: GameType.tournament, child: Text('Tournament')),
              DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => widget.template.gameType = v);
              _persist();
            },
          ),
          if (!narrow)
            IconButton(
              icon: Icon(Icons.push_pin, color: _pinnedOnly ? AppColors.accent : null),
              tooltip: 'Pinned Only',
              onPressed: () => setState(() => _pinnedOnly = !_pinnedOnly),
            ),
          IconButton(icon: const Text('↶'), onPressed: _canUndo ? _undo : null),
          IconButton(icon: const Text('↷'), onPressed: _canRedo ? _redo : null),
          IconButton(
            icon: const Text('🔄'),
            tooltip: 'Jump to last change',
            onPressed: _jumpToLastChange,
          ),
          IconButton(
            icon: Icon(_evAsc ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: 'Sort by EV',
            onPressed: _toggleEvSort,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Quick Filter',
            onSelected: (v) {
              setState(() => _quickFilter = _quickFilter == v ? null : v);
              _storeQuickFilter();
            },
            itemBuilder: (_) => [
              for (final f in _quickFilters)
                CheckedPopupMenuItem(value: f, checked: _quickFilter == f, child: Text(f)),
            ],
          ),
          if (_isMultiSelect)
            PopupMenuButton<String>(
              tooltip: 'Move to Tag',
              onSelected: _bulkMoveToTag,
              itemBuilder: (_) {
                final tags = widget.template.spots
                    .expand((s) => s.tags)
                    .toSet()
                    .toList()
                  ..sort((a, b) => a.compareTo(b));
                return [
                  const PopupMenuItem(value: '', child: Text('Untagged')),
                  for (final t in tags)
                    PopupMenuItem(value: t, child: Text(t)),
                ];
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: Text('Move to Tag')),
              ),
            ),
          if (_isMultiSelect)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Selected',
              onPressed: _bulkDelete,
            ),
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: (v) async {
              if (v == SortBy.autoEv) {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                  _autoSortEv = !_autoSortEv;
                  if (_autoSortEv) _sortSpots();
                });
                prefs.setBool(_prefsAutoSortKey, _autoSortEv);
              } else {
                setState(() => _sortBy = v);
                _storeSort();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: SortBy.manual, child: Text('Manual')),
              const PopupMenuItem(value: SortBy.title, child: Text('Title')),
              const PopupMenuItem(value: SortBy.evDesc, child: Text('EV')),
              const PopupMenuItem(value: SortBy.edited, child: Text('Edited')),
              PopupMenuItem(
                value: SortBy.autoEv,
                child: Row(
                  children: [
                    Checkbox(value: _autoSortEv, onChanged: null),
                    const SizedBox(width: 8),
                    const Text('Auto sort by EV'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'rename') _renameTag();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename Tag')),
            ],
          ),
          IconButton(
            icon: const Text('🏷️'),
            tooltip: 'Manage Tags',
            onPressed: _manageTags,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All Spots',
            onPressed: _clearAll,
          ),
          IconButton(icon: const Text('📋 Paste Spot'), onPressed: _pasteSpot),
          IconButton(icon: const Text('📥 Paste Hand'), onPressed: _pasteHandHistory),
          IconButton(icon: const Icon(Icons.upload), onPressed: _import),
          IconButton(icon: const Icon(Icons.download), onPressed: _export),
          IconButton(icon: const Text('📂 Preview Bundle'), onPressed: _previewBundle),
          IconButton(icon: const Icon(Icons.archive), onPressed: () => _exportBundle()),
          IconButton(icon: const Text('📤 Share'), onPressed: _shareBundle),
          IconButton(
            icon: const Text('🖼️'),
            tooltip: 'Export PNG Preview',
            onPressed: _exportPreview,
          ),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: _showSummary),
          IconButton(icon: const Text('🚦 Validate'), onPressed: _validateTemplate),
          IconButton(icon: const Text('⚙️ Settings'), onPressed: _showTemplateSettings),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'regenEv') _regenerateEv();
              if (v == 'regenIcm') _regenerateIcm();
              if (v == 'exportCsv') _exportCsv();
              if (v == 'tagMistakes') _tagAllMistakes();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'regenEv', child: Text('Regenerate EV')),
              PopupMenuItem(value: 'regenIcm', child: Text('Regenerate ICM')),
              PopupMenuItem(value: 'exportCsv', child: Text('Export CSV')),
              PopupMenuItem(value: 'tagMistakes', child: Text('Tag All Mistakes')),
            ],
          ),
          IconButton(
            onPressed: () async {
              await context
                  .read<TrainingSessionService>()
                  .startSession(widget.template, persist: false);
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TrainingSessionScreen()),
              );
            },
            icon: const Text('▶️ Playtest'),
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _save)
        ],
      ),
      floatingActionButton: hasSpots
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (narrow)
                  FloatingActionButton(
                    heroTag: 'filterSpotFab',
                    onPressed: _showFilters,
                    child: const Icon(Icons.filter_list),
                  ),
                if (narrow) const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'addSpotFab',
                  onPressed: _addSpot,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'generateSpotFab',
                  tooltip: 'Generate Spot',
                  onPressed: _generateSpot,
                  child: const Icon(Icons.auto_fix_high),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'generateSpotsFab',
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Generate Spots'),
                  onPressed: _generateSpots,
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'generateMissingFab',
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Generate Missing'),
                  onPressed: _generateMissingSpots,
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'evalAllSpotsFab',
                  icon: _evaluatingAll
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.playlist_play),
                  label: const Text('Evaluate All'),
                  onPressed: _evaluatingAll ? null : _evaluateAllSpots,
                ),
              ],
            )
          : null,
      bottomNavigationBar: hasSpots && _isMultiSelect
          ? BottomAppBar(
              child: Row(
                children: [
                  TextButton(
                    onPressed: _selectAll,
                    child: const Text('Select All'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _invertSelection,
                    child: const Text('Invert Selection'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _bulkAddTag,
                    child: const Text('Add Tag'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _bulkRemoveTag,
                    child: const Text('Remove Tag'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _bulkTogglePin,
                    child: const Text('Pin / Unpin'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _bulkMove,
                    child: const Text('Move to Pack'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _bulkCopy,
                    child: const Text('Copy to Pack'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _newPackFromSelection,
                    child: const Text('New Pack from Selection'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete'),
                    onPressed: _bulkDelete,
                  ),
                ],
              ),
            )
          : null,
      body: hasSpots
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
            TextField(
              controller: _descCtr,
              focusNode: _descFocus,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
              onEditingComplete: _saveDesc,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in widget.template.tags)
                  InputChip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() => widget.template.tags.remove(tag));
                      _persist();
                    },
                  ),
                InputChip(
                  label: const Text('+ Add'),
                  onPressed: _addPackTag,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GameType>(
              value: widget.template.gameType,
              decoration: const InputDecoration(labelText: 'Game Type'),
              items: const [
                DropdownMenuItem(value: GameType.tournament, child: Text('Tournament')),
                DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
              ],
              onChanged: (v) {
                setState(() => widget.template.gameType = v ?? GameType.tournament);
                _persist();
              },
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, set) => EvSummaryCard(
                values: _summaryIcm ? icmVals : chipVals,
                isIcm: _summaryIcm,
                onToggle: () => set(() => _summaryIcm = !_summaryIcm),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: RangeMatrixPicker(
                  selected: range,
                  onChanged: (_) {},
                  readOnly: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const _RangeLegend(),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Edit History', style: TextStyle(color: Colors.white)),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              collapsedTextColor: Colors.white,
              textColor: Colors.white,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_history.history.isEmpty)
                  const ListTile(
                    dense: true,
                    title: Text('No changes yet', style: TextStyle(color: Colors.white70)),
                  )
                else
                  for (final entry in historyGroups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(entry.key, style: const TextStyle(color: Colors.white70)),
                    ),
                    for (final e in entry.value)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          e.action == 'Added'
                              ? Icons.add_circle
                              : e.action == 'Deleted'
                                  ? Icons.remove_circle
                                  : e.action == 'Tagged'
                                      ? Icons.local_offer
                                      : e.action == 'Untagged'
                                          ? Icons.local_offer_outlined
                                          : Icons.edit,
                          color: e.action == 'Added'
                              ? Colors.green
                              : e.action == 'Deleted'
                                  ? Colors.red
                                  : e.action == 'Tagged'
                                      ? Colors.orange
                                      : e.action == 'Untagged'
                                          ? Colors.grey
                                          : Colors.blue,
                        ),
                        title: Text('${e.action}: ${e.title}',
                            style: const TextStyle(color: Colors.white)),
                        trailing: Text(DateFormat.Hm().format(e.time),
                            style: const TextStyle(color: Colors.white70)),
                      ),
                  ],
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search by title/tag',
                  prefixIcon: const Icon(Icons.search),
                  fillColor: _tagFilter == null ? null : Colors.yellow[50],
                  filled: _tagFilter != null,
                  suffixIcon: _tagFilter != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () async {
                            setState(() => _tagFilter = null);
                            _storeTagFilter();
                          },
                        )
                      : _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() {
                                _query = '';
                                _searchCtrl.clear();
                              }),
                            ),
                ),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            if (!narrow)
              Builder(
                builder: (context) {
                  final allTags = widget.template.spots
                      .expand((s) => s.tags)
                      .toSet()
                      .where((t) => t
                          .toLowerCase()
                          .contains(_tagSearch.toLowerCase()))
                      .toList();
                  return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _tagSearchCtrl,
                      decoration: InputDecoration(
                        labelText: 'Search tags',
                        suffixIcon: _tagSearch.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() {
                                  _tagSearch = '';
                                  _tagSearchCtrl.clear();
                                }),
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _tagSearch = v),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final tag in allTags)
                          FilterChip(
                            label: Text(tag),
                            selected: _selectedTags.contains(tag),
                            onSelected: (v) => setState(() {
                              v
                                  ? _selectedTags.add(tag)
                                  : _selectedTags.remove(tag);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('All')),
                        ButtonSegment(value: 'ok', label: Text('OK')),
                        ButtonSegment(value: 'error', label: Text('Errors')),
                        ButtonSegment(value: 'empty', label: Text('Empty')),
                      ],
                      selected: {_evFilter},
                      onSelectionChanged: (v) async {
                        final prefs = await SharedPreferences.getInstance();
                        final val = v.first;
                        setState(() => _evFilter = val);
                        prefs.setString(_prefsEvFilterKey, val);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _evFilter,
                      decoration: const InputDecoration(labelText: 'EV'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'ok', child: Text('OK')),
                        DropdownMenuItem(value: 'error', child: Text('Errors')),
                        DropdownMenuItem(value: 'empty', child: Text('Empty')),
                      ],
                      onChanged: (v) async {
                        final prefs = await SharedPreferences.getInstance();
                        final val = v ?? 'all';
                        setState(() => _evFilter = val);
                        prefs.setString(_prefsEvFilterKey, val);
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EV range (BB)',
                          style: TextStyle(color: Colors.white70)),
                      RangeSlider(
                        values: _evRange,
                        min: -5,
                        max: 5,
                        divisions: 100,
                        labels: RangeLabels(
                          _evRange.start.toStringAsFixed(1),
                          _evRange.end.toStringAsFixed(1),
                        ),
                        onChanged: (v) async {
                          setState(() => _evRange = v);
                          final prefs = await SharedPreferences.getInstance();
                          prefs.setString(
                              _prefsEvRangeKey, '${v.start},${v.end}');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_evRange.start.toStringAsFixed(1)} … ${_evRange.end.toStringAsFixed(1)} BB',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    setState(() => _evRange = const RangeValues(-5, 5));
                    prefs.setString(_prefsEvRangeKey, '-5.0,5.0');
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _generatingAll ? null : _generateAllEv,
                    child: _generatingAll
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate All'),
                  ),
                  ElevatedButton(
                    onPressed: _generatingIcm ? null : _generateAllIcm,
                    child: _generatingIcm
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate ICM'),
                  ),
                  ElevatedButton(
                    onPressed: _recalculateAll,
                    child: const Text('Recalculate All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _TemplateSummaryPanel(
              spots: totalSpots,
              ev: evCoverage,
              icm: icmCoverage,
              tags: summaryTags,
              avgEv: avgEv,
            ),
            const SizedBox(height: 8),
            _EvCoverageBar(ev: evCoverage, icm: icmCoverage, both: bothCoverage),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _tagFilter ?? '',
                decoration: const InputDecoration(labelText: 'Filter by tag'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All')),
                  for (final t in widget.template.spots
                      .expand((s) => s.tags)
                      .toSet()
                      .toList()
                    ..sort())
                    DropdownMenuItem(value: t.toLowerCase(), child: Text(t)),
                ],
                onChanged: (v) async {
                  setState(
                      () => _tagFilter = (v == null || v.isEmpty) ? null : v);
                  _storeTagFilter();
                },
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Hero push only'),
              value: _heroPushOnly,
              onChanged: (v) => setState(() => _heroPushOnly = v),
            ),
            SwitchListTile(
              title: const Text('Mistake only'),
              value: _mistakeOnly,
              onChanged: (v) => setState(() => _mistakeOnly = v),
            ),
            CheckboxListTile(
              title: const Text('Only Changed'),
              value: _changedOnly,
              onChanged: (v) => setState(() => _changedOnly = v ?? false),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  final groups = <String, List<TrainingPackSpot>>{};
                  for (final s in sorted) {
                    final tag = s.tags.isNotEmpty ? s.tags.first : '';
                    groups.putIfAbsent(tag, () => []).add(s);
                  }
                  final entries = groups.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));
                  return ListView.separated(
                    controller: _scrollCtrl,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, gIndex) {
                      final entry = entries[gIndex];
                      final spots = entry.value;
                      final start = sorted.indexOf(spots.first);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              entry.key.isEmpty ? 'Untagged' : entry.key,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: spots.length,
                            itemBuilder: (context, index) {
                              final spot = spots[index];
                      final selected = _selectedSpotIds.contains(spot.id);
                      final content = ReorderableDragStartListener(
                        key: ValueKey(spot.id),
                        index: index,
                        child: InkWell(
                          onTap: () async {
                            await showSpotViewerDialog(context, spot);
                            if (_autoSortEv) setState(() => _sortSpots());
                            _focusSpot(spot.id);
                          },
                          onLongPress: () => setState(() => _selectedSpotIds.add(spot.id)),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: RepaintBoundary(
                              key: _itemKeys.putIfAbsent(spot.id, () => GlobalKey()),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                color: spot.id == _highlightId ? Colors.yellow.withOpacity(0.3) : null,
                                padding: const EdgeInsets.all(8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isMultiSelect)
                                    Checkbox(
                                      value: selected,
                                      onChanged: (_) => setState(() {
                                        if (selected) {
                                          _selectedSpotIds.remove(spot.id);
                                        } else {
                                          _selectedSpotIds.add(spot.id);
                                        }
                                      }),
                                    ),
                                  Expanded(
                                  child: TrainingPackSpotPreviewCard(
                                      spot: spot,
                                      titleColor: spot.evalResult == null
                                          ? Colors.yellow
                                          : (spot.evalResult!.correct ? null : Colors.red),
                                      onHandEdited: () {
                                        setState(() {
                                          if (_autoSortEv) _sortSpots();
                                        });
                                        _persist();
                                      },
                                      onTagTap: (tag) async {
                                        setState(() => _tagFilter = tag);
                                        _storeTagFilter();
                                      },
                                      onDuplicate: () {
                                        final i = widget.template.spots.indexOf(spot);
                                        if (i == -1) return;
                                        final copy = spot.copyWith(
                                          id: const Uuid().v4(),
                                          editedAt: DateTime.now(),
                                          hand: HandData.fromJson(spot.hand.toJson()),
                                          tags: List.from(spot.tags),
                                        );
                                        setState(() => widget.template.spots.insert(i + 1, copy));
                                        _persist();
                                        _focusSpot(copy.id);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'copy') {
                                            _copiedSpot = spot.copyWith(
                                              id: const Uuid().v4(),
                                              editedAt: DateTime.now(),
                                              hand: HandData.fromJson(spot.hand.toJson()),
                                              tags: List.from(spot.tags),
                                            );
                                          } else if (v == 'paste' && _copiedSpot != null) {
                                            final i = widget.template.spots.indexOf(spot);
                                            final s = _copiedSpot!.copyWith(
                                              id: const Uuid().v4(),
                                              editedAt: DateTime.now(),
                                              hand: HandData.fromJson(_copiedSpot!.hand.toJson()),
                                              tags: List.from(_copiedSpot!.tags),
                                            );
                                            setState(() => widget.template.spots.insert(i + 1, s));
                                            _persist();
                                          } else if (v == 'dup') {
                                            _duplicateSpot(spot);
                                          } else if (v == 'pin') {
                                            setState(() {
                                              spot.pinned = !spot.pinned;
                                              if (_autoSortEv) _sortSpots();
                                            });
                                            _persist();
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(value: 'pin', child: Text(spot.pinned ? '📌 Unpin' : '📌 Pin')),
                                          const PopupMenuItem(value: 'copy', child: Text('📋 Copy')),
                                          if (_copiedSpot != null) const PopupMenuItem(value: 'paste', child: Text('📥 Paste')),
                                          const PopupMenuItem(value: 'dup', child: Text('📄 Duplicate')),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () => _openEditor(spot),
                                        child: const Text('📝 Edit'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Delete spot?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                              ],
                                            ),
                                          );
                                          if (ok ?? false) {
                                            final t = spot.title;
                                            setState(() => widget.template.spots.removeAt(index));
                                            _persist();
                                            setState(() => _history.log('Deleted', t, spot.id));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                              return Dismissible(
                                key: ValueKey(spot.id),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.copy, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (dir) async {
                          if (dir == DismissDirection.startToEnd) {
                            _duplicateSpot(spot);
                          } else {
                            _lastRemoved = [spot];
                            final t = spot.title;
                            setState(() => widget.template.spots.remove(spot));
                            _persist();
                            setState(() => _history.log('Deleted', t, spot.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Deleted'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () {
                                    setState(() {
                                      widget.template.spots.addAll(_lastRemoved!);
                                      if (_autoSortEv) _sortSpots();
                                    });
                                    _persist();
                                  },
                                ),
                              ),
                            );
                          }
                          return false;
                        },
                                child: content,
                              );
                            },
                        onReorder: (o, n) {
                          _recordSnapshot();
                          final spot = spots[o];
                          final oldIndex = widget.template.spots.indexOf(spot);
                          final newSorted = n < spots.length ? start + n : start + spots.length;
                          final newIndex = newSorted < sorted.length
                              ? widget.template.spots.indexOf(sorted[newSorted])
                              : widget.template.spots.length;
                          setState(() {
                            final s = widget.template.spots.removeAt(oldIndex);
                            widget.template.spots.insert(
                                newIndex > oldIndex ? newIndex - 1 : newIndex, s);
                          });
                          _persist();
                        },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ),
            ],
          ),
        ),
      )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 96, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'This pack is empty. Tap + to add your first spot or 📋 to paste from JSON',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addSpot,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Spot'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pasteSpot,
                        icon: const Text('📋'),
                        label: const Text('Paste JSON'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pasteHandHistory,
                        icon: const Text('📥'),
                        label: const Text('Paste Hand'),
                      ),
                    ],
                  ),
                ],
              ),
            );
  }
}

class _TemplatePreviewCard extends StatelessWidget {
  final TrainingPackTemplate template;
  const _TemplatePreviewCard({required this.template});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (template.description.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(template.description),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Spots: ${template.spots.length}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageTagTile extends StatefulWidget {
  final String tag;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;
  const _ManageTagTile({super.key, required this.tag, required this.onRename, required this.onDelete});

  @override
  State<_ManageTagTile> createState() => _ManageTagTileState();
}

class _ManageTagTileState extends State<_ManageTagTile> {
  late TextEditingController _ctr;

  @override
  void initState() {
    super.initState();
    _ctr = TextEditingController(text: widget.tag);
  }

  @override
  void didUpdateWidget(covariant _ManageTagTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag) _ctr.text = widget.tag;
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Text('✏️'),
      title: TextField(
        controller: _ctr,
        decoration: const InputDecoration(border: InputBorder.none),
        onSubmitted: (v) {
          final t = v.trim();
          if (t.isEmpty || t == widget.tag) {
            _ctr.text = widget.tag;
          } else {
            widget.onRename(t);
          }
        },
      ),
      trailing: IconButton(
        icon: const Text('🗑️'),
        onPressed: widget.onDelete,
      ),
    );
  }
}

class _EvCoverageBar extends StatelessWidget {
  final double ev;
  final double icm;
  final double both;
  const _EvCoverageBar({required this.ev, required this.icm, required this.both});

  Widget _bar(BuildContext context, double value, String label, Color color) {
    final percent = (value * 100).round();
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text('$label $percent%',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Row(
      children: [
        _bar(context, ev, 'EV', accent),
        const SizedBox(width: 8),
        _bar(context, icm, 'ICM', Colors.purple),
        const SizedBox(width: 8),
        _bar(context, both, 'Both', Colors.green),
      ],
    );
  }
}

class _TemplateSummaryPanel extends StatelessWidget {
  final int spots;
  final double ev;
  final double icm;
  final List<String> tags;
  final double? avgEv;
  const _TemplateSummaryPanel({
    required this.spots,
    required this.ev,
    required this.icm,
    required this.tags,
    required this.avgEv,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spots: $spots', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('EV ${(ev * 100).round()}%  •  ICM ${(icm * 100).round()}%',
              style: const TextStyle(color: Colors.white70)),
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final t in tags)
                    Chip(
                      backgroundColor: Colors.grey[800],
                      label: Text(t, style: const TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          if (avgEv != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Avg EV: ${(avgEv! >= 0 ? '+' : '')}${avgEv!.toStringAsFixed(2)} BB',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeLegend extends StatelessWidget {
  const _RangeLegend();

  Widget _item(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: c),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _item(Colors.orange, 'Pairs'),
        const SizedBox(width: 12),
        _item(Colors.green, 'Suited'),
        const SizedBox(width: 12),
        _item(Colors.blue, 'Offsuit'),
      ],
    );
  }
}

class _MatrixPickerPage extends StatefulWidget {
  final Set<String> initial;
  const _MatrixPickerPage({required this.initial});

  @override
  State<_MatrixPickerPage> createState() => _MatrixPickerPageState();
}

class _MatrixPickerPageState extends State<_MatrixPickerPage> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Range'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text('OK'),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: RangeMatrixPicker(
            selected: _selected,
            onChanged: (v) => setState(() => _selected = v),
          ),
        ),
      ),
    );
  }
}
