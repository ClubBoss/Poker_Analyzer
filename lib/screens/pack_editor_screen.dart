import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/tag_service.dart';
import '../helpers/color_utils.dart';
import '../theme/app_colors.dart';
import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../models/view_preset.dart';
import '../services/training_pack_storage_service.dart';
import 'room_hand_history_import_screen.dart';
import 'room_hand_history_editor_screen.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/view_manager_dialog.dart';
import '../models/pack_editor_snapshot.dart';
import '../widgets/snapshot_manager_dialog.dart';
import '../widgets/saved_hand_viewer_dialog.dart';

enum _SortOption { newest, oldest, position, tags, mistakes }

enum _MistakeFilter { any, zero, oneTwo, threePlus }

enum _QcIssue { duplicateName, noHeroCards, noActions }

class _Command {
  final String id;
  final String label;
  final LogicalKeySet? shortcut;
  final VoidCallback action;
  _Command(this.id, this.label, this.shortcut, this.action);
}

class _CommandIntent extends Intent {
  final String id;
  const _CommandIntent(this.id);
}

class PackEditorScreen extends StatefulWidget {
  final TrainingPack pack;
  const PackEditorScreen({super.key, required this.pack});

  @override
  State<PackEditorScreen> createState() => _PackEditorScreenState();
}

class _PackEditorScreenState extends State<PackEditorScreen> {
  static const _sortKey = 'pack_editor_sort';
  static const _searchKey = 'pack_editor_search';
  static const _lastCheckKey = 'pack_editor_last_quality_check';

  late List<SavedHand> _hands;
  late List<String> _packTags;
  late TrainingPack _packRef;
  bool _modified = false;
  SavedHand? _removed;
  int _removedIndex = -1;
  final Set<SavedHand> _selected = {};
  bool get _selectionMode => _selected.isNotEmpty;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  _SortOption _sort = _SortOption.newest;
  static const _tagKey = 'pack_editor_tag_filter';
  static const _mistakeKey = 'pack_editor_mistake_filter';
  static const _heroKey = 'pack_editor_hero_filter';
  static const _viewsKey = 'pack_editor_views';
  String? _tagFilter;
  _MistakeFilter _mistakeFilter = _MistakeFilter.any;
  bool _showFind = false;
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  bool _regex = false;
  bool _matchCase = false;
  List<(int, String)> _renameUndo = [];
  List<(int, List<String>)> _tagsUndo = [];
  String? _heroPosFilter;
  Map<String, int> _tagsCount = {};
  int _mist0 = 0;
  int _mist12 = 0;
  int _mist3 = 0;
  Map<String, int> _posCount = {
    'UTG': 0,
    'MP': 0,
    'CO': 0,
    'BTN': 0,
    'SB': 0,
    'BB': 0,
  };
  int _dupCount = 0;
  List<ViewPreset> _views = [];
  List<PackEditorSnapshot> _snapshots = [];
  Timer? _autoTimer;
  List<_Command> _commands = [];
  bool _filtersVisible = true;
  bool _filterConflict = false;
  List<List<SavedHand>> _history = [];
  int _historyIndex = 0;
  bool _skipHistory = false;

  @override
  void setState(VoidCallback fn) {
    super.setState(() {
      fn();
      _detectDuplicates();
      if (!_skipHistory) _pushHistory();
    });
  }

  @override
  void initState() {
    super.initState();
    _hands = List.from(widget.pack.hands);
    _packTags = List.from(widget.pack.tags);
    _packRef = widget.pack;
    _detectDuplicates();
    _history = [List.from(_hands)];
    _historyIndex = 0;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sort = _SortOption.values[prefs.getInt(_sortKey) ?? 0];
      _searchController.text = prefs.getString(_searchKey) ?? '';
      _showSearch = _searchController.text.isNotEmpty;
      _tagFilter = prefs.getString(_tagKey);
      final m = prefs.getInt(_mistakeKey) ?? 0;
      _mistakeFilter =
          _MistakeFilter.values[m.clamp(0, _MistakeFilter.values.length - 1)];
      _heroPosFilter = prefs.getString(_heroKey);
      _rebuildStats();
    });
    final raw = prefs.getString(_viewsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final list = data[widget.pack.id];
        if (list is List) {
          final order = [
            for (final v in list) Map<String, dynamic>.from(v as Map)
          ];
          setState(() {
            _views = [for (final m in order) ViewPreset.fromJson(m)];
          });
        }
      } catch (_) {}
    }
    final snapsRaw = prefs.getString('snapshots_${widget.pack.id}');
    if (snapsRaw != null) {
      try {
        final list = jsonDecode(snapsRaw) as List;
        setState(() {
          _snapshots = [
            for (final s in list)
              PackEditorSnapshot.fromJson(Map<String, dynamic>.from(s as Map))
          ];
        });
      } catch (_) {}
    }
    setState(_buildCommands);
    await _maybeRestoreAutoSnapshot(prefs);
    _autoTimer ??=
        Timer.periodic(const Duration(seconds: 60), (_) => _autoSaveSnapshot());
  }

  LogicalKeySet _primaryCmd(LogicalKeyboardKey key) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return LogicalKeySet(
        isMac ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control, key);
  }

  void _buildCommands() {
    _commands = [
      _Command(
        'save',
        'Save',
        _primaryCmd(LogicalKeyboardKey.keyS),
        _hands.isEmpty ? () {} : _save,
      ),
      _Command(
        'find',
        'Toggle Find',
        _primaryCmd(LogicalKeyboardKey.keyF),
        _toggleFind,
      ),
      _Command(
        'export',
        'Export',
        _primaryCmd(LogicalKeyboardKey.keyE),
        _exportPack,
      ),
      _Command(
        'auto',
        'Auto-Tag',
        LogicalKeySet(
            LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyA),
        () async {
          final r = await _showAutoTagDialog();
          if (r != null) _autoTag(r.$1, r.$2);
        },
      ),
      _Command(
        'quality',
        'Quality Check',
        LogicalKeySet(
            LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyQ),
        _qualityCheck,
      ),
      _Command(
        'importhh',
        'Import HH',
        LogicalKeySet(
            LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyH),
        _importFromRoom,
      ),
      _Command('import', 'Import', null, _addHands),
      _Command('snapshot', 'Save Snapshot', null, _saveSnapshot),
      _Command('manageSnaps', 'Manage Snapshots…', null, _manageSnapshots),
      _Command('stats', 'Stats', null, _showStats),
      _Command('filters', 'Toggle Filters', null, _toggleFilters),
      _Command('saveView', 'Save View', null, _saveCurrentView),
      _Command('manageViews', 'Manage Views…', null, _manageViews),
      _Command('move', 'Bulk Move', null, () => _bulkTransfer('move')),
      _Command('copy', 'Bulk Copy', null, () => _bulkTransfer('copy')),
      _Command(
        'up',
        'Move Up',
        _primaryCmd(LogicalKeyboardKey.arrowUp),
        _moveUp,
      ),
      _Command(
        'down',
        'Move Down',
        _primaryCmd(LogicalKeyboardKey.arrowDown),
        _moveDown,
      ),
    ];
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  List<SavedHand> _parseCsv(String content) {
    final lines = content.trim().split(RegExp(r'\r?\n'));
    if (lines.length < 2) return [];
    final headers = _parseCsvLine(lines.first);
    final hands = <SavedHand>[];
    for (int i = 1; i < lines.length; i++) {
      final values = _parseCsvLine(lines[i]);
      if (values.every((v) => v.trim().isEmpty)) continue;
      final map = <String, String>{};
      for (int j = 0; j < headers.length && j < values.length; j++) {
        map[headers[j]] = values[j];
      }
      hands.add(
        SavedHand(
          name: map['name'] ?? '',
          heroIndex: 0,
          heroPosition: map['heroPosition'] ?? 'BTN',
          numberOfPlayers: 2,
          playerCards: const [],
          boardCards: const [],
          boardStreet: 0,
          actions: const [],
          stackSizes: const {},
          playerPositions: const {},
          comment: map['comment'],
          tags: (map['tags'] ?? '')
              .split('|')
              .where((e) => e.isNotEmpty)
              .toList(),
          tournamentId: map['tournamentId'],
          buyIn: int.tryParse(map['buyIn'] ?? ''),
          totalPrizePool: int.tryParse(map['totalPrizePool'] ?? ''),
          numberOfEntrants: int.tryParse(map['numberOfEntrants'] ?? ''),
          gameType: map['gameType'],
          savedAt: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
          date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
        ),
      );
    }
    return hands;
  }

  Future<void> _addHands() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['json', 'hand.json', 'csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final added = <SavedHand>[];
    for (final f in result.files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final content = await File(path).readAsString();
        if (path.endsWith('.csv')) {
          added.addAll(_parseCsv(content));
        } else {
          final data = jsonDecode(content);
          if (data is Map<String, dynamic>) {
            added.add(SavedHand.fromJson(data));
          } else if (data is List) {
            for (final e in data) {
              if (e is Map<String, dynamic>) {
                added.add(SavedHand.fromJson(e));
              }
            }
          }
        }
      } catch (_) {}
    }
    if (added.isEmpty) return;
    setState(() {
      for (final h in added) {
        if (_hands.every((e) => e.savedAt != h.savedAt)) {
          _hands.add(h);
          _modified = true;
        }
      }
      _rebuildStats();
    });
  }

  Future<void> _importFromRoom() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomHandHistoryImportScreen(pack: _packRef),
      ),
    );
    final updated = context.read<TrainingPackStorageService>().packs.firstWhere(
      (p) => p.id == _packRef.id,
      orElse: () => _packRef,
    );
    setState(() {
      _hands = List.from(updated.hands);
      _rebuildStats();
    });
  }

  Future<void> _previewHand(SavedHand hand) async {
    await showSavedHandViewerDialog(context, hand);
  }

  Future<void> _editHand(SavedHand hand) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RoomHandHistoryEditorScreen(pack: _packRef, hands: [hand]),
      ),
    );
    final updated = context.read<TrainingPackStorageService>().packs.firstWhere(
      (p) => p.id == _packRef.id,
      orElse: () => _packRef,
    );
    setState(() {
      _hands = List.from(updated.hands);
      _rebuildStats();
    });
  }

  void _remove(int index) {
    if (index < 0 || index >= _hands.length) return;
    final hand = _hands.removeAt(index);
    setState(() {
      _removed = hand;
      _removedIndex = index;
      _modified = true;
      _rebuildStats();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Раздача удалена'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (_removed != null) {
              setState(() {
                _hands.insert(_removedIndex.clamp(0, _hands.length), _removed!);
                _removed = null;
                _modified = true;
                _rebuildStats();
              });
            }
          },
        ),
      ),
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _hands.removeAt(oldIndex);
      _hands.insert(newIndex, item);
      _modified = true;
      _rebuildStats();
    });
  }

  void _moveUp() {
    if (_selected.length == 1) {
      final i = _hands.indexOf(_selected.first);
      if (i > 0) _reorder(i, i - 1);
    }
  }

  void _moveDown() {
    if (_selected.length == 1) {
      final i = _hands.indexOf(_selected.first);
      if (i < _hands.length - 1) _reorder(i, i + 1);
    }
  }

  void _undo() {
    if (_historyIndex > 0) {
      _skipHistory = true;
      setState(() {
        _historyIndex--;
        _hands = [for (final h in _history[_historyIndex]) h];
        _rebuildStats();
      });
      _skipHistory = false;
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      _skipHistory = true;
      setState(() {
        _historyIndex++;
        _hands = [for (final h in _history[_historyIndex]) h];
        _rebuildStats();
      });
      _skipHistory = false;
    }
  }

  void _toggleSelect(SavedHand hand) {
    setState(() {
      if (_selected.contains(hand)) {
        _selected.remove(hand);
      } else {
        _selected.add(hand);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  void _deleteSelected() {
    final removed = <(SavedHand, int)>[];
    setState(() {
      for (final h in _selected) {
        final i = _hands.indexOf(h);
        if (i != -1) {
          removed.add((h, i));
          _hands.removeAt(i);
          _modified = true;
        }
      }
      _selected.clear();
      _rebuildStats();
    });
    if (removed.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Раздачи удалены'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in removed.reversed) {
                _hands.insert(r.$2.clamp(0, _hands.length), r.$1);
              }
              _modified = true;
              _rebuildStats();
            });
          },
        ),
      ),
    );
  }

  void _applyTagToSelected(String tag) {
    setState(() {
      for (final h in _selected) {
        final set = {...h.tags, tag};
        final idx = _hands.indexOf(h);
        if (idx != -1) {
          _hands[idx] = h.copyWith(tags: set.toList());
          _modified = true;
        }
      }
      _rebuildStats();
    });
  }

  void _removeTagFromSelected(String tag) {
    setState(() {
      for (final h in _selected) {
        if (h.tags.contains(tag)) {
          final list = List<String>.from(h.tags)..remove(tag);
          final idx = _hands.indexOf(h);
          if (idx != -1) {
            _hands[idx] = h.copyWith(tags: list);
            _modified = true;
          }
        }
      }
      _rebuildStats();
    });
  }

  Future<void> _addTagDialog() async {
    final allTags = context.read<TagService>().tags;
    final c = TextEditingController();
    String? selected;
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Add Tag', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 4,
                children: [
                  for (final t in allTags)
                    ChoiceChip(
                      label: Text(
                        t,
                        style: const TextStyle(color: Colors.white),
                      ),
                      selected: selected == t,
                      selectedColor: Colors
                          .primaries[t.hashCode % Colors.primaries.length],
                      onSelected: (_) => setStateDialog(() => selected = t),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (v) {
                  final input = v.text.toLowerCase();
                  if (input.isEmpty) return allTags;
                  return allTags.where((e) => e.toLowerCase().contains(input));
                },
                onSelected: (s) => setStateDialog(() => selected = s),
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
                    decoration: const InputDecoration(hintText: 'Tag'),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, selected ?? c.text.trim()),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    c.dispose();
    if (tag != null && tag.isNotEmpty) _applyTagToSelected(tag);
  }

  Future<void> _removeTagDialog() async {
    final allTags = context.read<TagService>().tags;
    String? selected;
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Remove Tag',
            style: TextStyle(color: Colors.white),
          ),
          content: Wrap(
            spacing: 4,
            children: [
              for (final t in allTags)
                ChoiceChip(
                  label: Text(t, style: const TextStyle(color: Colors.white)),
                  selected: selected == t,
                  selectedColor:
                      Colors.primaries[t.hashCode % Colors.primaries.length],
                  onSelected: (_) => setStateDialog(() => selected = t),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (tag != null && tag.isNotEmpty) _removeTagFromSelected(tag);
  }

  Future<void> _editComment(SavedHand hand) async {
    final idx = _hands.indexOf(hand);
    if (idx == -1) return;
    final c = TextEditingController(text: hand.comment ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment'),
        content: TextField(controller: c, maxLines: null),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    if (!mounted || result == null) return;
    final old = _hands[idx].comment;
    setState(() {
      _hands[idx] = _hands[idx].copyWith(comment: result.isNotEmpty ? result : null);
      _modified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Comment updated'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _hands[idx] = _hands[idx].copyWith(comment: old);
              _modified = true;
            });
          },
        ),
      ),
    );
  }

  Future<TrainingPack?> _pickTargetPack() async {
    final service = context.read<TrainingPackStorageService>();
    final packs = [
      for (final p in service.packs)
        if (!p.isBuiltIn && p.id != _packRef.id) p,
    ];
    String filter = '';
    TrainingPack? selected;
    return showDialog<TrainingPack>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final visible = [
            for (final p in packs)
              if (p.name.toLowerCase().contains(filter.toLowerCase())) p,
          ];
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Select Pack',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(hintText: 'Search'),
                    onChanged: (v) => setStateDialog(() => filter = v),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final p in visible)
                          RadioListTile<TrainingPack>(
                            value: p,
                            groupValue: selected,
                            onChanged: (v) =>
                                setStateDialog(() => selected = v),
                            title: Text(
                              p.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: selected == null
                    ? null
                    : () => Navigator.pop(context, selected),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _bulkTransfer(String action) async {
    if (_selected.isEmpty) return;
    final target = await _pickTargetPack();
    if (target == null) return;
    final selected = _selected.toList();
    final service = context.read<TrainingPackStorageService>();
    var pack = service.packs.firstWhere(
      (p) => p.id == target.id,
      orElse: () => target,
    );
    final existing = {
      for (final h in pack.hands) h.savedAt.millisecondsSinceEpoch,
    };
    final toAdd = [
      for (final h in selected)
        if (!existing.contains(h.savedAt.millisecondsSinceEpoch))
          (action == 'copy' ? h.copyWith() : h),
    ];
    final removed = <(SavedHand, int)>[];
    setState(() {
      if (action == 'move') {
        for (final h in selected) {
          final i = _hands.indexOf(h);
          if (i != -1) {
            removed.add((h, i));
            _hands.removeAt(i);
          }
        }
        _modified = true;
      }
      _selected.clear();
    });
    service.applyDiff(pack, added: toAdd);
    final msg =
        '${action == 'move' ? 'Moved' : 'Copied'} ${selected.length} hands to "${pack.name}"';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final svc = context.read<TrainingPackStorageService>();
            final tgt = svc.packs.firstWhere(
              (p) => p.id == pack.id,
              orElse: () => pack,
            );
            svc.applyDiff(tgt, removed: toAdd);
            if (action == 'move') {
              setState(() {
                for (final r in removed.reversed) {
                  _hands.insert(r.$2.clamp(0, _hands.length), r.$1);
                }
                _modified = true;
              });
            }
          },
        ),
      ),
    );
  }

  int _mistakeCount(SavedHand hand) {
    int total = 0;
    int correct = 0;
    for (final session in widget.pack.history) {
      for (final task in session.tasks) {
        if (task.question == hand.name) {
          total += 1;
          if (task.correct) correct += 1;
        }
      }
    }
    return total - correct;
  }

  List<int> _visibleIndices() {
    final query = _searchController.text.toLowerCase();
    final list = <int>[for (int i = 0; i < _hands.length; i++) i];
    if (query.isNotEmpty) {
      list.retainWhere((i) {
        final h = _hands[i];
        if (h.name.toLowerCase().contains(query)) return true;
        return h.tags.any((t) => t.toLowerCase().contains(query));
      });
    }
    if (_tagFilter != null) {
      list.retainWhere((i) => _hands[i].tags.contains(_tagFilter));
    }
    if (_mistakeFilter != _MistakeFilter.any) {
      list.retainWhere((i) {
        final m = _mistakeCount(_hands[i]);
        switch (_mistakeFilter) {
          case _MistakeFilter.zero:
            return m == 0;
          case _MistakeFilter.oneTwo:
            return m >= 1 && m <= 2;
          case _MistakeFilter.threePlus:
            return m >= 3;
          case _MistakeFilter.any:
            return true;
        }
      });
    }
    if (_heroPosFilter != null) {
      list.retainWhere((i) => _hands[i].heroPosition == _heroPosFilter);
    }
    int posIdx(String p) {
      const order = ['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB'];
      return order.indexOf(p);
    }

    list.sort((a, b) {
      final A = _hands[a];
      final B = _hands[b];
      switch (_sort) {
        case _SortOption.newest:
          return B.savedAt.compareTo(A.savedAt);
        case _SortOption.oldest:
          return A.savedAt.compareTo(B.savedAt);
        case _SortOption.position:
          final ai = posIdx(A.heroPosition);
          final bi = posIdx(B.heroPosition);
          if (ai != bi) return ai.compareTo(bi);
          return B.savedAt.compareTo(A.savedAt);
        case _SortOption.tags:
          final at = A.tags.isEmpty ? '' : A.tags.first;
          final bt = B.tags.isEmpty ? '' : B.tags.first;
          final c = at.compareTo(bt);
          if (c != 0) return c;
          return B.savedAt.compareTo(A.savedAt);
        case _SortOption.mistakes:
          final am = _mistakeCount(A);
          final bm = _mistakeCount(B);
          if (am != bm) return bm.compareTo(am);
          return B.savedAt.compareTo(A.savedAt);
      }
    });
    return list;
  }

  void _detectDuplicates() {
    final map = <String, List<int>>{};
    for (int i = 0; i < _hands.length; i++) {
      final h = _hands[i];
      final key = '${h.heroPosition}-${h.playerCards.map((p) => p.map((c) => c.toString()).join()).join('/')}-${h.actions.map((a) => '${a.playerIndex}${a.action}${a.amount ?? 0}').join()}';
      map.putIfAbsent(key, () => []).add(i);
    }
    final list = List<SavedHand>.from(_hands);
    int dup = 0;
    for (final entry in map.values) {
      if (entry.length > 1) {
        dup += entry.length;
        for (final i in entry) {
          list[i] = list[i].copyWith(isDuplicate: true);
        }
      } else {
        final i = entry.first;
        list[i] = list[i].copyWith(isDuplicate: false);
      }
    }
    _hands = list;
    _dupCount = dup;
  }

  bool _handsEqual(List<SavedHand> a, List<SavedHand> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!mapEquals(a[i].toJson(), b[i].toJson())) return false;
    }
    return true;
  }

  void _pushHistory() {
    final snap = [for (final h in _hands) h];
    if (_history.isNotEmpty && _handsEqual(_history[_historyIndex], snap)) return;
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(snap);
    if (_history.length > 20) _history.removeAt(0);
    _historyIndex = _history.length - 1;
  }

  void _rebuildStats() {
    _filterConflict = false;
    final indices = _visibleIndices();
    final Map<String, int> tags = {};
    int m0 = 0;
    int m12 = 0;
    int m3 = 0;
    final pos = {'UTG': 0, 'MP': 0, 'CO': 0, 'BTN': 0, 'SB': 0, 'BB': 0};
    for (final i in indices) {
      final h = _hands[i];
      for (final t in h.tags) {
        tags[t] = (tags[t] ?? 0) + 1;
      }
      final m = _mistakeCount(h);
      if (m == 0) {
        m0++;
      } else if (m <= 2) {
        m12++;
      } else {
        m3++;
      }
      final p = h.heroPosition;
      if (pos.containsKey(p)) pos[p] = pos[p]! + 1;
    }
    _tagsCount = tags;
    _mist0 = m0;
    _mist12 = m12;
    _mist3 = m3;
    _posCount = pos;
    _dupCount = _hands.where((h) => h.isDuplicate).length;
    _filterConflict =
        _hands.isNotEmpty && indices.isEmpty && _searchController.text.isEmpty;
  }

  Future<bool> _onWillPop() async {
    if (!_modified) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить изменения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _save();
      setState(() => _modified = false);
      return true;
    }
    if (result == 'discard') return true;
    return false;
  }

  Future<void> _save() async {
    final updated = TrainingPack(
      name: widget.pack.name,
      description: widget.pack.description,
      category: widget.pack.category,
      gameType: widget.pack.gameType,
      colorTag: widget.pack.colorTag,
      isBuiltIn: widget.pack.isBuiltIn,
      tags: _packTags,
      hands: _hands,
      spots: widget.pack.spots,
      difficulty: widget.pack.difficulty,
    );
    await context.read<TrainingPackStorageService>().updatePack(
      _packRef,
      updated,
    );
    _packRef = updated;
    _renameUndo.clear();
    _tagsUndo.clear();
  }

  Future<void> _saveAndExit() async {
    await _save();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _commitChanges() async {
    await _save();
    if (mounted) setState(() => _modified = false);
  }

  Future<void> _saveSnapshot() async {
    final df = DateFormat('dd.MM HH:mm');
    final c = TextEditingController(text: df.format(DateTime.now()));
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Snapshot'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name == null) return;
    final snap = PackEditorSnapshot(
      name: name,
      hands: [for (final h in _hands) h],
      views: [for (final v in _views) v],
      filters: {
        'sort': _sort.index,
        'tag': _tagFilter,
        'mistake': _mistakeFilter.index,
        'hero': _heroPosFilter,
        'search': _searchController.text,
      },
    );
    setState(() => _snapshots.add(snap));
    await _saveSnapshots();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Snapshot saved')));
    }
  }

  Future<void> _manageSnapshots() async {
    final manual = [for (final s in _snapshots) if (!s.isAuto) s];
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => SnapshotManagerDialog(snapshots: manual),
    );
    if (!mounted) return;
    if (result is PackEditorSnapshot) {
      final snap = result;
      setState(() {
        _hands = [for (final h in snap.hands) h];
        _views = [for (final v in snap.views) v];
        _modified = true;
      });
      await _applySnapshotFilters(snap.filters);
      await _saveViews();
    } else if (result is List<PackEditorSnapshot>) {
      final autos = [for (final s in _snapshots) if (s.isAuto) s];
      setState(() => _snapshots = [...autos, ...result]);
      await _saveSnapshots();
    }
  }

  Future<void> _setSort(_SortOption value) async {
    setState(() {
      _modified = true;
      _sort = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortKey, value.index);
  }

  Future<void> _setSearch(String value) async {
    setState(() {
      _modified = true;
      _rebuildStats();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchKey, value);
  }

  Future<void> _setTagFilter(String? value) async {
    setState(() {
      _modified = true;
      _tagFilter = value;
      _rebuildStats();
    });
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_tagKey);
    } else {
      await prefs.setString(_tagKey, value);
    }
  }

  Future<void> _setMistakeFilter(_MistakeFilter value) async {
    setState(() {
      _modified = true;
      _mistakeFilter = value;
      _rebuildStats();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mistakeKey, value.index);
  }

  Future<void> _setHeroFilter(String? value) async {
    setState(() {
      _modified = true;
      _heroPosFilter = value;
      _rebuildStats();
    });
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_heroKey);
    } else {
      await prefs.setString(_heroKey, value);
    }
  }

  Future<void> _saveViews() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_viewsKey);
    Map<String, dynamic> data = {};
    if (raw != null) {
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    data[widget.pack.id] = _views.map((e) => e.toJson()).toList();
    await prefs.setString(_viewsKey, jsonEncode(data));
  }

  Future<void> _saveSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'snapshots_${widget.pack.id}',
      jsonEncode([for (final s in _snapshots) s.toJson()]),
    );
  }

  Future<void> _autoSaveSnapshot() async {
    final snap = PackEditorSnapshot(
      name: 'Auto ${DateFormat('HH:mm').format(DateTime.now())}',
      hands: [for (final h in _hands) h],
      views: [for (final v in _views) v],
      filters: {
        'sort': _sort.index,
        'tag': _tagFilter,
        'mistake': _mistakeFilter.index,
        'hero': _heroPosFilter,
        'search': _searchController.text,
      },
      isAuto: true,
    );
    _skipHistory = true;
    setState(() {
      _snapshots.add(snap);
      final autos = [for (final s in _snapshots) if (s.isAuto) s]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      while (autos.length > 10) {
        _snapshots.remove(autos.removeAt(0));
      }
    });
    _skipHistory = false;
    await _saveSnapshots();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'last_auto_snapshot_${widget.pack.id}', jsonEncode(snap.toJson()));
  }

  Future<void> _maybeRestoreAutoSnapshot([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString('last_auto_snapshot_${widget.pack.id}');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw);
      final snap =
          PackEditorSnapshot.fromJson(Map<String, dynamic>.from(data as Map));
      final restore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Auto Snapshot?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes')),
          ],
        ),
      );
      await prefs.remove('last_auto_snapshot_${widget.pack.id}');
      if (restore == true) {
        setState(() {
          _hands = [for (final h in snap.hands) h];
          _views = [for (final v in snap.views) v];
          _modified = true;
        });
        await _applySnapshotFilters(snap.filters);
        await _saveViews();
      }
    } catch (_) {}
  }

  Future<void> _applySnapshotFilters(Map<String, dynamic> f) async {
    await _setSort(_SortOption.values[(f['sort'] as num?)?.toInt() ?? 0]);
    await _setTagFilter(f['tag'] as String?);
    await _setMistakeFilter(
        _MistakeFilter.values[(f['mistake'] as num?)?.toInt() ?? 0]);
    await _setHeroFilter(f['hero'] as String?);
    _searchController.text = f['search'] as String? ?? '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchKey, _searchController.text);
    setState(() => _rebuildStats());
  }

  Future<void> _saveCurrentView() async {
    if (_views.length >= 20) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Too many views')));
      return;
    }
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('View Name'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final view = ViewPreset(
      name: name,
      sort: _sort.index,
      tagFilter: _tagFilter,
      mistakeFilter: _mistakeFilter.index,
      heroPosFilter: _heroPosFilter,
      search: _searchController.text,
    );
    setState(() => _views.add(view));
    await _saveViews();
  }

  Future<void> _applyView(ViewPreset view) async {
    await _setSort(_SortOption.values[view.sort]);
    await _setTagFilter(view.tagFilter);
    await _setMistakeFilter(_MistakeFilter.values[view.mistakeFilter]);
    await _setHeroFilter(view.heroPosFilter);
    _searchController.text = view.search;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchKey, view.search);
    setState(() => _rebuildStats());
  }

  Future<void> _manageViews() async {
    await showDialog(
      context: context,
      builder: (_) => ViewManagerDialog(
        views: _views,
        onChanged: (v) async {
          setState(() => _views = List.from(v));
          await _saveViews();
        },
      ),
    );
  }


  Future<void> _exportPack() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Text('📸', style: TextStyle(fontSize: 20)),
              title: const Text('Save Snapshot'),
              onTap: () => Navigator.pop(ctx, 'snapshot'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Export JSON'),
              onTap: () => Navigator.pop(ctx, 'json'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export CSV'),
              onTap: () => Navigator.pop(ctx, 'csv'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    if (action == 'snapshot') {
      await _saveSnapshot();
      return;
    }
    var format = action;
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Pack',
      fileName: format == 'json' ? 'pack_export.json' : 'pack_export.csv',
      type: FileType.custom,
      allowedExtensions: [format],
    );
    if (savePath == null) return;
    final file = File(savePath);
    if (format == 'json') {
      final map = {
        'name': widget.pack.name,
        'hands': [for (final h in _hands) h.toJson()]
      };
      await file.writeAsString(jsonEncode(map), encoding: utf8);
    } else {
      final rows = [
        for (final h in _hands)
          [h.name, h.heroPosition, h.tags.join(', '), h.comment ?? '']
      ];
      final csvStr = const ListToCsvConverter().convert(rows);
      await file.writeAsString(csvStr, encoding: utf8);
    }
    if (!mounted) return;
    final name = savePath.split(Platform.pathSeparator).last;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Файл сохранён: $name')));
  }

  Future<(bool, bool)?> _showAutoTagDialog() {
    bool hero = true;
    bool severity = true;
    return showDialog<(bool, bool)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Auto-Tag', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: hero,
                onChanged: (v) => setStateDialog(() => hero = v ?? false),
                title: const Text(
                  'Hero Position',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              CheckboxListTile(
                value: severity,
                onChanged: (v) => setStateDialog(() => severity = v ?? false),
                title: const Text(
                  'Mistake Severity',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, (hero, severity)),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autoTag(bool hero, bool severity) async {
    final tagService = context.read<TagService>();
    final previous = <(int, List<String>)>[];
    final newTags = <String>{};
    int count = 0;
    setState(() {
      for (int i = 0; i < _hands.length; i++) {
        final hand = _hands[i];
        final before = List<String>.from(hand.tags);
        final set = {...hand.tags};
        if (hero && !set.contains(hand.heroPosition)) {
          set.add(hand.heroPosition);
        }
        if (severity) {
          final m = _mistakeCount(hand);
          final tag = m == 0
              ? 'mistake:0'
              : m <= 2
                  ? 'mistake:1-2'
                  : 'mistake:3+';
          set.add(tag);
        }
        if (!setEquals(before.toSet(), set)) {
          _hands[i] = hand.copyWith(tags: set.toList());
          previous.add((i, before));
          count++;
          _modified = true;
          for (final t in set) {
            if (!tagService.tags.contains(t)) newTags.add(t);
          }
        }
      }
      _rebuildStats();
    });
    for (final t in newTags) {
      await tagService.addTag(t);
    }
    if (count == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-tagged $count hands'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in previous) {
                _hands[r.$1] = _hands[r.$1].copyWith(tags: r.$2);
              }
              _modified = true;
              _rebuildStats();
            });
          },
        ),
      ),
    );
  }

  Future<void> _qualityCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    final indices = _visibleIndices();
    final issues = {
      _QcIssue.duplicateName: <int>[],
      _QcIssue.noHeroCards: <int>[],
      _QcIssue.noActions: <int>[],
    };
    final nameMap = <String, List<int>>{};
    for (final i in indices) {
      final h = _hands[i];
      nameMap.putIfAbsent(h.name, () => []).add(i);
      if (h.playerCards.length <= h.heroIndex ||
          h.playerCards[h.heroIndex].isEmpty) {
        issues[_QcIssue.noHeroCards]!.add(i);
      }
      if (h.actions.isEmpty) issues[_QcIssue.noActions]!.add(i);
    }
    for (final e in nameMap.entries) {
      if (e.value.length > 1) issues[_QcIssue.duplicateName]!.addAll(e.value);
    }
    String title(_QcIssue t) {
      switch (t) {
        case _QcIssue.duplicateName:
          return 'Duplicate Name';
        case _QcIssue.noHeroCards:
          return 'No Hero Cards';
        case _QcIssue.noActions:
          return 'No Actions';
      }
    }

    String desc(_QcIssue t) {
      switch (t) {
        case _QcIssue.duplicateName:
          return 'Duplicate name';
        case _QcIssue.noHeroCards:
          return 'Missing hero cards';
        case _QcIssue.noActions:
          return 'No actions';
      }
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Quality Check',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final t in _QcIssue.values)
                if (issues[t]!.isNotEmpty)
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white,
                      textColor: Colors.white,
                      collapsedTextColor: Colors.white,
                      title: Text(
                        '${title(t)} (${issues[t]!.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: [
                        for (final i in issues[t]!)
                          ListTile(
                            title: Text(
                              _hands[i].name.isEmpty
                                  ? '(no name)'
                                  : _hands[i].name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              desc(t),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            onLongPress: () => _previewHand(_hands[i]),
                          ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: issues[_QcIssue.duplicateName]!.isEmpty
                ? null
                : () => Navigator.pop(context, 'dup'),
            child: const Text('Fix duplicates'),
          ),
          TextButton(
            onPressed: issues[_QcIssue.noActions]!.isEmpty
                ? null
                : () => Navigator.pop(context, 'empty'),
            child: const Text('Remove empty'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == 'dup') {
      _fixDuplicates(issues[_QcIssue.duplicateName]!);
    } else if (result == 'empty') {
      _removeEmptyHands(issues[_QcIssue.noActions]!);
    }
  }

  void _fixDuplicates(List<int> indices) {
    final previous = <(int, String)>[];
    final counts = <String, int>{};
    int changed = 0;
    setState(() {
      for (final i in indices) {
        final name = _hands[i].name;
        final c = (counts[name] ?? 0) + 1;
        counts[name] = c;
        if (c > 1) {
          var suffix = c;
          var newName = '${name}_$suffix';
          while (_hands.any((h) => h.name == newName)) {
            suffix++;
            newName = '${name}_$suffix';
          }
          previous.add((i, name));
          _hands[i] = _hands[i].copyWith(name: newName);
          changed++;
          _modified = true;
        }
      }
      _rebuildStats();
    });
    if (changed == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fixed $changed issues'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final e in previous) {
                _hands[e.$1] = _hands[e.$1].copyWith(name: e.$2);
              }
              _modified = true;
              _rebuildStats();
            });
          },
        ),
      ),
    );
  }

  void _removeEmptyHands(List<int> indices) {
    final removed = <(SavedHand, int)>[];
    setState(() {
      for (final i in indices.toList()..sort().reversed) {
        removed.add((_hands[i], i));
        _hands.removeAt(i);
        _modified = true;
      }
      _rebuildStats();
    });
    if (removed.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fixed ${removed.length} issues'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in removed.reversed) {
                _hands.insert(r.$2.clamp(0, _hands.length), r.$1);
              }
              _modified = true;
              _rebuildStats();
            });
          },
        ),
      ),
    );
  }

  void _toggleFind() {
    setState(() => _showSearch = !_showSearch);
  }

  void _toggleFilters() {
    setState(() => _filtersVisible = !_filtersVisible);
    if (_filterConflict &&
        _tagFilter != null &&
        _heroPosFilter != null &&
        _mistakeFilter != _MistakeFilter.any) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hands match current filters'),
          action: SnackBarAction(
            label: 'Clear',
            onPressed: () {
              _setTagFilter(null);
              _setHeroFilter(null);
              _setMistakeFilter(_MistakeFilter.any);
            },
          ),
        ),
      );
    }
  }

  Future<void> _showCommandPalette() async {
    String query = '';
    int index = 0;
    final focus = FocusNode();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final list = [
            for (final c in _commands)
              if (query.isEmpty || c.label.toLowerCase().contains(query.toLowerCase())) c
          ];
          index = index.clamp(0, list.length - 1);
          return RawKeyboardListener(
            focusNode: focus,
            autofocus: true,
            onKey: (e) {
              if (e is RawKeyDownEvent) {
                if (e.logicalKey == LogicalKeyboardKey.escape) {
                  Navigator.of(ctx).pop();
                } else if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                  if (index < list.length - 1) setStateDialog(() => index++);
                } else if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                  if (index > 0) setStateDialog(() => index--);
                } else if (e.logicalKey == LogicalKeyboardKey.enter && list.isNotEmpty) {
                  Navigator.pop(ctx);
                  list[index].action();
                }
              }
            },
            child: AlertDialog(
              backgroundColor: Colors.grey[900],
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(hintText: 'Command'),
                      onChanged: (v) => setStateDialog(() {
                        query = v;
                        index = 0;
                      }),
                      onSubmitted: (_) {
                        if (list.isNotEmpty) {
                          Navigator.pop(ctx);
                          list[index].action();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final c = list[i];
                          return Container(
                            color: i == index
                                ? Colors.blue.withOpacity(0.4)
                                : Colors.transparent,
                            child: ListTile(
                              title: Text(c.label),
                              trailing: c.shortcut == null
                                  ? null
                                  : Text(_shortcutLabel(c.shortcut!)),
                              onTap: () {
                                Navigator.pop(ctx);
                                c.action();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '↑/↓ navigate • Enter run',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _shortcutLabel(LogicalKeySet set) {
    return set.keys
        .map((k) {
          if (k == LogicalKeyboardKey.control) return 'Ctrl';
          if (k == LogicalKeyboardKey.meta) return '⌘';
          if (k == LogicalKeyboardKey.shift) return 'Shift';
          if (k == LogicalKeyboardKey.alt) return 'Alt';
          return k.keyLabel.toUpperCase();
        })
        .join(' + ');
  }

  Future<void> _showRenameDialog() async {
    final list = _selected.toList()
      ..sort((a, b) => _hands.indexOf(a).compareTo(_hands.indexOf(b)));
    String template = '#{index} – {old}';
    final c = TextEditingController(text: template);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          List<String> preview = [
            for (int i = 0; i < list.length && i < 3; i++)
              c.text
                  .replaceAll('{index}', '${i + 1}')
                  .replaceAll('{old}', list[i].name),
          ];
          return AlertDialog(
            title: const Text('Rename'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: c,
                  onChanged: (_) => setStateDialog(() {}),
                ),
                const SizedBox(height: 8),
                for (final p in preview) Text(p),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, c.text),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
    if (result != null) _applyRename(result, list);
    c.dispose();
  }

  void _applyRename(String template, List<SavedHand> list) {
    _renameUndo = [];
    setState(() {
      for (int i = 0; i < list.length; i++) {
        final h = list[i];
        final idx = _hands.indexOf(h);
        final newName = template
            .replaceAll('{index}', '${i + 1}')
            .replaceAll('{old}', h.name);
        if (_hands[idx].name != newName) {
          _renameUndo.add((idx, _hands[idx].name));
          _hands[idx] = _hands[idx].copyWith(name: newName);
          _modified = true;
        }
      }
      _rebuildStats();
    });
    if (_renameUndo.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Renamed ${_renameUndo.length} hands'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in _renameUndo) {
                _hands[r.$1] = _hands[r.$1].copyWith(name: r.$2);
              }
              _modified = true;
              _rebuildStats();
            });
          },
        ),
      ),
    );
  }

  void _replaceAll() {
    final indices = _visibleIndices();
    final pattern = _regex
        ? RegExp(_findController.text, caseSensitive: _matchCase)
        : RegExp(
            RegExp.escape(_findController.text),
            caseSensitive: _matchCase,
          );
    _renameUndo = [];
    setState(() {
      for (final i in indices) {
        final h = _hands[i];
        final newName = h.name.replaceAll(pattern, _replaceController.text);
        if (newName != h.name) {
          _renameUndo.add((i, h.name));
          _hands[i] = h.copyWith(name: newName);
          _modified = true;
        }
      }
      _rebuildStats();
    });
    if (_renameUndo.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Renamed ${_renameUndo.length} hands'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in _renameUndo) {
                _hands[r.$1] = _hands[r.$1].copyWith(name: r.$2);
              }
              _modified = true;
              _rebuildStats();
            });
          },
        ),
      ),
    );
  }

  Future<(String, String)?> _showReplaceTagsDialog() {
    final f = TextEditingController();
    final r = TextEditingController();
    return showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace Tags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: f,
              decoration: const InputDecoration(hintText: 'Find'),
            ),
            TextField(
              controller: r,
              decoration: const InputDecoration(hintText: 'Replace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, (f.text.trim(), r.text.trim())),
            child: const Text('OK'),
          ),
        ],
      ),
    ).whenComplete(() {
      f.dispose();
      r.dispose();
    });
  }

  void _replaceTags(String find, String replace) {
    _tagsUndo = [];
    int count = 0;
    setState(() {
      for (int i = 0; i < _hands.length; i++) {
        final h = _hands[i];
        if (h.tags.contains(find)) {
          final old = List<String>.from(h.tags);
          final set = {...h.tags}..remove(find);
          if (replace.isNotEmpty) set.add(replace);
          _hands[i] = h.copyWith(tags: set.toList());
          _tagsUndo.add((i, old));
          _modified = true;
          count++;
        }
      }
      _rebuildStats();
    });
    if (count == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated $count hands'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in _tagsUndo) {
                _hands[r.$1] = _hands[r.$1].copyWith(tags: r.$2);
              }
              _modified = true;
              _rebuildStats();
            });
          },
        ),
      ),
    );
  }

  void _removeTagEverywhere(String tag) {
    _tagsUndo = [];
    int count = 0;
    setState(() {
      for (int i = 0; i < _hands.length; i++) {
        final h = _hands[i];
        if (h.tags.contains(tag)) {
          final old = List<String>.from(h.tags);
          final list = List<String>.from(h.tags)..remove(tag);
          _hands[i] = h.copyWith(tags: list);
          _tagsUndo.add((i, old));
          _modified = true;
          count++;
        }
      }
      _rebuildStats();
    });
    if (count == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated $count hands'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in _tagsUndo) {
                _hands[r.$1] = _hands[r.$1].copyWith(tags: r.$2);
              }
              _modified = true;
              _rebuildStats();
            });
          },
        ),
      ),
    );
  }

  void _showStats() {
    _rebuildStats();
    final tagService = context.read<TagService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final tags = _tagsCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            const Text('Tags', style: TextStyle(color: Colors.white70)),
            for (final e in tags)
              ListTile(
                leading: Checkbox(
                  value: _tagFilter == e.key,
                  onChanged: (v) {
                    _setTagFilter(v == true ? e.key : null);
                    Navigator.pop(ctx);
                  },
                ),
                title: Chip(
                  label: Text(
                    e.key,
                    style: _tagFilter == e.key
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                  backgroundColor: colorFromHex(tagService.colorOf(e.key)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${e.value}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text("Remove tag '${e.key}' from all hands?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) _removeTagEverywhere(e.key);
                      },
                    )
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text('Mistakes', style: TextStyle(color: Colors.white70)),
            ListTile(
              title: const Text('0', style: TextStyle(color: Colors.white)),
              trailing: Text(
                '$_mist0',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                _setMistakeFilter(_MistakeFilter.zero);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('1-2', style: TextStyle(color: Colors.white)),
              trailing: Text(
                '$_mist12',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                _setMistakeFilter(_MistakeFilter.oneTwo);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('3+', style: TextStyle(color: Colors.white)),
              trailing: Text(
                '$_mist3',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                _setMistakeFilter(_MistakeFilter.threePlus);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Hero Position',
              style: TextStyle(color: Colors.white70),
            ),
            for (final p in ['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB'])
              ListTile(
                title: Text(p, style: const TextStyle(color: Colors.white)),
                trailing: Text(
                  '${_posCount[p] ?? 0}',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _setSearch('');
                  _setTagFilter(null);
                  _setHeroFilter(p);
                  Navigator.pop(ctx);
                },
              ),
            const Divider(),
            ListTile(
              title: Text(
                'Duplicates: $_dupCount',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _searchController.dispose();
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enableShortcuts = kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS);
    final shortcutMap = <LogicalKeySet, Intent>{};
    if (enableShortcuts) {
      final shortcutToId = <LogicalKeySet, String>{};
      void addShortcut(LogicalKeySet? set, String id) {
        if (set == null) return;
        shortcutToId[set] = id;
      }
      addShortcut(const LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK), 'palette');
      addShortcut(const LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK), 'palette');
      for (final c in _commands) addShortcut(c.shortcut, c.id);
      shortcutMap
        ..clear()
        ..addEntries(shortcutToId.entries
            .map((e) => MapEntry(e.key, _CommandIntent(e.value))));
    }

    Widget child = WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: _selectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : null,
          title: Text(
            _selectionMode ? '${_selected.length}' : widget.pack.name,
          ),
          actions: _selectionMode
              ? [
                  IconButton(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete),
                  ),
                  IconButton(
                    onPressed: _addTagDialog,
                    icon: const Icon(Icons.label),
                  ),
                  IconButton(
                    onPressed: _removeTagDialog,
                    icon: const Icon(Icons.label_off),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.forward),
                    onSelected: _bulkTransfer,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'move',
                        child: Text('Move to Pack…'),
                      ),
                      PopupMenuItem(
                        value: 'copy',
                        child: Text('Copy to Pack…'),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'all') {
                        setState(
                          () => _selected
                            ..clear()
                            ..addAll(_hands),
                        );
                      } else if (v == 'rename') {
                        _showRenameDialog();
                      } else {
                        _clearSelection();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename…')),
                      PopupMenuItem(value: 'all', child: Text('Select All')),
                      PopupMenuItem(value: 'none', child: Text('Select None')),
                    ],
                  ),
                ]
              : [
                  SyncStatusIcon.of(context),
                  IconButton(
                    onPressed: _historyIndex > 0 ? _undo : null,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    onPressed:
                        _historyIndex < _history.length - 1 ? _redo : null,
                    icon: const Icon(Icons.redo),
                  ),
                  IconButton(
                    onPressed: _showCommandPalette,
                    icon: const Icon(Icons.settings_suggest),
                  ),
                  IconButton(
                    onPressed: _qualityCheck,
                    icon: const Icon(Icons.rule),
                    tooltip: 'Quality Check',
                  ),
                  IconButton(
                    onPressed: _showStats,
                    icon: const Icon(Icons.bar_chart),
                  ),
                  IconButton(
                    onPressed: _importFromRoom,
                    icon: const Icon(Icons.playlist_add),
                  ),
                  IconButton(
                    onPressed: _exportPack,
                    icon: const Icon(Icons.share),
                  ),
                  IconButton(
                    onPressed: _saveCurrentView,
                    icon: const Icon(Icons.star_outline),
                  ),
                  PopupMenuButton<_SortOption>(
                    icon: const Icon(Icons.sort),
                    initialValue: _sort,
                    onSelected: _setSort,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _SortOption.newest,
                        child: Text('Newest'),
                      ),
                      PopupMenuItem(
                        value: _SortOption.oldest,
                        child: Text('Oldest'),
                      ),
                      PopupMenuItem(
                        value: _SortOption.mistakes,
                        child: Text('Most Mistakes'),
                      ),
                    ],
                  ),
                  PopupMenuButton<String?>(
                    icon: const Icon(Icons.filter_list),
                    onSelected: _setHeroFilter,
                    itemBuilder: (_) => [
                      const PopupMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      for (final p in ['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB'])
                        PopupMenuItem<String?>(
                          value: p,
                          child: Text(p),
                        ),
                    ],
                  ),
                  PopupMenuButton<_MistakeFilter>(
                    icon: Icon(
                      _mistakeFilter == _MistakeFilter.any
                          ? Icons.bug_report_outlined
                          : Icons.bug_report,
                    ),
                    initialValue: _mistakeFilter,
                    onSelected: _setMistakeFilter,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _MistakeFilter.any,
                        child: Text('All'),
                      ),
                      PopupMenuItem(
                        value: _MistakeFilter.zero,
                        child: Text('0'),
                      ),
                      PopupMenuItem(
                        value: _MistakeFilter.oneTwo,
                        child: Text('1-2'),
                      ),
                      PopupMenuItem(
                        value: _MistakeFilter.threePlus,
                        child: Text('3+'),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.star),
                    onSelected: (v) {
                      if (v == 'manage') {
                        _manageViews();
                      } else if (v == 'save') {
                        _saveCurrentView();
                      } else {
                        final view = _views.firstWhere(
                          (e) => e.id == v,
                          orElse: () => ViewPreset(name: '', sort: 0, mistakeFilter: 0, search: ''),
                        );
                        if (view.name.isNotEmpty) _applyView(view);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'save', child: Text('Save Current View')),
                      for (final v in _views)
                        PopupMenuItem(value: v.id, child: Text(v.name)),
                      const PopupMenuItem(value: 'manage', child: Text('Manage Views…')),
                    ],
                  ),
                  IconButton(
                    onPressed: _toggleFind,
                    icon: const Icon(Icons.search),
                  ),
                  TextButton(
                    onPressed: _modified ? _commitChanges : null,
                    child: const Text('Commit Changes'),
                  ),
                  IconButton(
                    onPressed: _hands.isEmpty ? null : _saveAndExit,
                    icon: const Icon(Icons.check),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'snap') {
                        _saveSnapshot();
                      } else if (v == 'manage') {
                        _manageSnapshots();
                      } else if (v == 'tags') {
                        _showReplaceTagsDialog().then((r) {
                          if (r != null && r.$1.isNotEmpty) {
                            _replaceTags(r.$1, r.$2);
                          }
                        });
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'snap',
                        child: Text('Save Snapshot'),
                      ),
                      PopupMenuItem(
                        value: 'manage',
                        child: Text('Manage Snapshots…'),
                      ),
                      PopupMenuItem(
                        value: 'tags',
                        child: Text('Replace Tags…'),
                      ),
                    ],
                  ),
                ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await _showAutoTagDialog();
            if (result != null) _autoTag(result.$1, result.$2);
          },
          child: const Icon(Icons.auto_fix_high),
        ),
        body: Column(
          children: [
            if (_tagFilter != null ||
                _heroPosFilter != null ||
                _mistakeFilter != _MistakeFilter.any)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_tagFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_tagFilter!),
                          backgroundColor: colorFromHex(
                              context.read<TagService>().colorOf(_tagFilter!)),
                          onDeleted: () => _setTagFilter(null),
                        ),
                      ),
                    if (_heroPosFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_heroPosFilter!),
                          onDeleted: () => _setHeroFilter(null),
                        ),
                      ),
                    if (_mistakeFilter != _MistakeFilter.any)
                      Chip(
                        label: Text(() {
                          switch (_mistakeFilter) {
                            case _MistakeFilter.zero:
                              return '0';
                            case _MistakeFilter.oneTwo:
                              return '1-2';
                            case _MistakeFilter.threePlus:
                              return '3+';
                            case _MistakeFilter.any:
                              return 'Any';
                          }
                        }()),
                        onDeleted: () =>
                            _setMistakeFilter(_MistakeFilter.any),
                      ),
                  ],
                ),
              ),
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Поиск'),
                  onChanged: _setSearch,
                ),
              ),
            if (_showFind)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _findController,
                            decoration: const InputDecoration(hintText: 'Find'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _replaceController,
                            decoration: const InputDecoration(
                              hintText: 'Replace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            value: _regex,
                            onChanged: (v) =>
                                setState(() => _regex = v ?? false),
                            title: const Text('Regex'),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            value: _matchCase,
                            onChanged: (v) =>
                                setState(() => _matchCase = v ?? false),
                            title: const Text('Match case'),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                        TextButton(
                          onPressed: _replaceAll,
                          child: const Text('Replace All'),
                        ),
                        TextButton(
                          onPressed: _toggleFind,
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_filtersVisible)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<_SortOption>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) {
                    if (v != null) _setSort(v);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: _SortOption.newest,
                      child: Text('Newest'),
                    ),
                  DropdownMenuItem(
                    value: _SortOption.oldest,
                    child: Text('Oldest'),
                  ),
                  DropdownMenuItem(
                    value: _SortOption.position,
                    child: Text('Hero Pos'),
                  ),
                  DropdownMenuItem(
                    value: _SortOption.tags,
                    child: Text('Tags'),
                  ),
                  DropdownMenuItem(
                    value: _SortOption.mistakes,
                    child: Text('Mistakes'),
                  ),
                ],
              ),
            ),
            if (_filtersVisible)
              SizedBox(
                height: 36,
                child: Consumer<TagService>(
                  builder: (context, service, _) {
                    final tags = service.tags;
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: _tagFilter == null,
                            onSelected: (_) => _setTagFilter(null),
                          ),
                        ),
                        for (final t in tags)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(t),
                              selected: _tagFilter == t,
                              selectedColor: colorFromHex(service.colorOf(t)),
                              onSelected: (_) => _setTagFilter(t),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            if (_filtersVisible)
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: const Text('Any'),
                        selected: _mistakeFilter == _MistakeFilter.any,
                        onSelected: (_) =>
                            _setMistakeFilter(_MistakeFilter.any),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: const Text('0'),
                        selected: _mistakeFilter == _MistakeFilter.zero,
                        onSelected: (_) =>
                            _setMistakeFilter(_MistakeFilter.zero),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: const Text('1-2'),
                        selected: _mistakeFilter == _MistakeFilter.oneTwo,
                        onSelected: (_) =>
                            _setMistakeFilter(_MistakeFilter.oneTwo),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: const Text('3+'),
                        selected: _mistakeFilter == _MistakeFilter.threePlus,
                        onSelected: (_) =>
                            _setMistakeFilter(_MistakeFilter.threePlus),
                      ),
                    ),
                  ],
                ),
              ),
            if (_filterConflict)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'No hands match current filters',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: ReorderableListView.builder(
                onReorder: (oldIndex, newIndex) {
                  final indices = _visibleIndices();
                  final oldGlobal = indices[oldIndex];
                  final newGlobal =
                      indices[(newIndex > oldIndex ? newIndex - 1 : newIndex)];
                  _reorder(oldGlobal, newGlobal);
                },
                itemCount: _visibleIndices().length,
                itemBuilder: (context, index) {
                  final indices = _visibleIndices();
                  final hand = _hands[indices[index]];
                  final title = hand.name.isEmpty ? 'Без названия' : hand.name;
                  final mistakes = _mistakeCount(hand);
                  return Dismissible(
                    key: ValueKey(hand.savedAt.toIso8601String()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _remove(indices[index]),
                    child: ListTile(
                      leading: _selectionMode
                          ? Checkbox(
                              value: _selected.contains(hand),
                              onChanged: (_) => _toggleSelect(hand),
                            )
                          : const Icon(Icons.drag_handle),
                      title: Row(
                        children: [
                          Expanded(child: Text(title)),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            onSelected: (p) async {
                              final idx = _hands.indexOf(hand);
                              if (idx == -1) return;
                              if (p == 'comment') {
                                final c = TextEditingController(text: hand.comment ?? '');
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Comment'),
                                    content: TextField(
                                      controller: c,
                                      maxLines: null,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, c.text.trim()),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                c.dispose();
                                if (!mounted) return;
                                if (result != null) {
                                  final old = _hands[idx].comment;
                                  final trimmed = result.trim();
                                  setState(() {
                                    _hands[idx] = _hands[idx].copyWith(
                                      comment: trimmed.isNotEmpty ? trimmed : null,
                                    );
                                    _modified = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Comment updated'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          setState(() {
                                            _hands[idx] = _hands[idx].copyWith(comment: old);
                                            _modified = true;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                }
                              } else if (['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB'].contains(p)) {
                                setState(() {
                                  _hands[idx] = _hands[idx].copyWith(heroPosition: p);
                                  _modified = true;
                                  _rebuildStats();
                                });
                              }
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(hand.heroPosition),
                            ),
                            itemBuilder: (_) => [
                              for (final pos
                                  in ['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB'])
                                PopupMenuItem(
                                  value: pos,
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(pos)),
                                      if (hand.heroPosition == pos)
                                        const Icon(Icons.check, size: 16),
                                    ],
                                  ),
                                ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'comment',
                                child: Text('📝 Comment'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      subtitle: hand.tags.isEmpty && hand.comment == null
                          ? null
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hand.tags.isNotEmpty)
                                  Text(hand.tags.join(', ')),
                                if (hand.tags.isNotEmpty && hand.comment != null)
                                  const SizedBox(height: 4),
                                if (hand.comment != null)
                                  Text(
                                    hand.comment!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hand.isDuplicate)
                            const Icon(Icons.warning, color: Colors.orangeAccent),
                          IconButton(
                            icon: const Text('✏️'),
                            onPressed: () => _editComment(hand),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: mistakes > 0 ? Colors.red : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$mistakes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (_selectionMode) {
                          _toggleSelect(hand);
                        } else {
                          _editHand(hand);
                        }
                      },
                      onLongPress: () {
                        if (_selectionMode) {
                          _toggleSelect(hand);
                        } else {
                          _toggleSelect(hand);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addHands,
                      child: const Text('Файл'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _importFromRoom,
                      child: const Text('Импорт HH'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (enableShortcuts) {
      child = Shortcuts(
        shortcuts: shortcutMap,
        child: Actions(
          actions: {
            _CommandIntent: CallbackAction<_CommandIntent>(onInvoke: (intent) {
              if (intent.id == 'palette') {
                _showCommandPalette();
              } else {
                for (final c in _commands) {
                  if (c.id == intent.id) {
                    c.action();
                    break;
                  }
                }
              }
              return null;
            }),
          },
          child: Focus(autofocus: true, child: child),
        ),
      );
    }

    return child;
  }
}
