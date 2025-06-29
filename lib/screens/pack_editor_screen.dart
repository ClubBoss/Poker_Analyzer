import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/tag_service.dart';
import '../helpers/color_utils.dart';
import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../models/pack_snapshot.dart';
import '../services/training_pack_storage_service.dart';
import 'room_hand_history_import_screen.dart';
import 'room_hand_history_editor_screen.dart';
import '../widgets/sync_status_widget.dart';
import 'snapshot_manager_screen.dart';

enum _SortOption { newest, oldest, position, tags, mistakes }
enum _MistakeFilter { any, zero, oneTwo, threePlus }
enum _QcIssue { duplicateName, noHeroCards, noActions }

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

  _SortOption _sort = _SortOption.newest;
  static const _tagKey = 'pack_editor_tag_filter';
  static const _mistakeKey = 'pack_editor_mistake_filter';
  String? _tagFilter;
  _MistakeFilter _mistakeFilter = _MistakeFilter.any;

  @override
  void initState() {
    super.initState();
    _hands = List.from(widget.pack.hands);
    _packTags = List.from(widget.pack.tags);
    _packRef = widget.pack;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sort = _SortOption.values[prefs.getInt(_sortKey) ?? 0];
      _searchController.text = prefs.getString(_searchKey) ?? '';
      _tagFilter = prefs.getString(_tagKey);
      final m = prefs.getInt(_mistakeKey) ?? 0;
      _mistakeFilter = _MistakeFilter.values[m.clamp(0, _MistakeFilter.values.length - 1)];
    });
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
    });
  }

  Future<void> _importFromRoom() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => RoomHandHistoryImportScreen(pack: _packRef)),
    );
    final updated = context
        .read<TrainingPackStorageService>()
        .packs
        .firstWhere((p) => p.id == _packRef.id, orElse: () => _packRef);
    setState(() => _hands = List.from(updated.hands));
  }

  Future<void> _previewHand(SavedHand hand) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(hand.name.isEmpty ? 'Без названия' : hand.name,
                style:
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${hand.heroPosition} • ${hand.numberOfPlayers}p',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Actions: ${hand.actions.length}',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Future<void> _editHand(SavedHand hand) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              RoomHandHistoryEditorScreen(pack: _packRef, hands: [hand])),
    );
    final updated = context
        .read<TrainingPackStorageService>()
        .packs
        .firstWhere((p) => p.id == _packRef.id, orElse: () => _packRef);
    setState(() => _hands = List.from(updated.hands));
  }

  void _remove(int index) {
    if (index < 0 || index >= _hands.length) return;
    final hand = _hands.removeAt(index);
    setState(() {
      _removed = hand;
      _removedIndex = index;
      _modified = true;
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
    });
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
                      label: Text(t, style: const TextStyle(color: Colors.white)),
                      selected: selected == t,
                      selectedColor:
                          Colors.primaries[t.hashCode % Colors.primaries.length],
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
              onPressed: () => Navigator.pop(context, selected ?? c.text.trim()),
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
          title: const Text('Remove Tag', style: TextStyle(color: Colors.white)),
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
      list.retainWhere((i) => _hands[i].name.toLowerCase().contains(query));
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

  Future<bool> _onWillPop() async {
    if (!_modified) return true;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить изменения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (save == true) {
      await _save();
      return true;
    }
    return save ?? false;
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
    await context
        .read<TrainingPackStorageService>()
        .updatePack(_packRef, updated);
    _packRef = updated;
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _saveSnapshot() async {
    final df = DateFormat('dd.MM HH:mm');
    final c = TextEditingController(text: df.format(DateTime.now()));
    final comment = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Snapshot'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (comment == null) return;
    final snap = await context
        .read<TrainingPackStorageService>()
        .saveSnapshot(_packRef, _hands, _packTags, comment);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Snapshot saved'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => context
              .read<TrainingPackStorageService>()
              .deleteSnapshot(_packRef, snap),
        ),
      ),
    );
  }

  Future<void> _manageSnapshots() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SnapshotManagerScreen(pack: _packRef)),
    );
    if (!mounted) return;
    if (result is PackSnapshot) {
      final snap = result as PackSnapshot;
      setState(() {
        _hands = [for (final h in snap.hands) h];
        _packTags = List.from(snap.tags);
        _modified = true;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pack_editor_last_snapshot_restored', snap.id);
    } else if (result == true) {
      final pack = context
          .read<TrainingPackStorageService>()
          .packs
          .firstWhere((p) => p.id == _packRef.id, orElse: () => _packRef);
      setState(() {
        _packRef = pack;
        _hands = List.from(pack.hands);
        _packTags = List.from(pack.tags);
        _modified = true;
      });
    }
  }

  Future<void> _setSort(_SortOption value) async {
    setState(() => _sort = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortKey, value.index);
  }

  Future<void> _setSearch(String value) async {
    setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchKey, value);
  }

  Future<void> _setTagFilter(String? value) async {
    setState(() => _tagFilter = value);
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_tagKey);
    } else {
      await prefs.setString(_tagKey, value);
    }
  }

  Future<void> _setMistakeFilter(_MistakeFilter value) async {
    setState(() => _mistakeFilter = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mistakeKey, value.index);
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
                title: const Text('Hero Position',
                    style: TextStyle(color: Colors.white)),
              ),
              CheckboxListTile(
                value: severity,
                onChanged: (v) => setStateDialog(() => severity = v ?? false),
                title: const Text('Mistake Severity',
                    style: TextStyle(color: Colors.white)),
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
    final indices = _visibleIndices();
    final tagService = context.read<TagService>();
    final previous = <(int, List<String>)>[];
    final newTags = <String>{};
    int count = 0;
    setState(() {
      for (final i in indices) {
        final hand = _hands[i];
        final before = List<String>.from(hand.tags);
        final set = {...hand.tags};
        if (hero) set.add(hand.heroPosition);
        if (severity) {
          final m = _mistakeCount(hand);
          final tag = m == 0
              ? 'Clean'
              : m <= 2
                  ? 'Minor'
                  : 'Major';
          set.add(tag);
        }
        if (!set.containsAll(before) || set.length != before.length) {
          _hands[i] = hand.copyWith(tags: set.toList());
          previous.add((i, before));
          count++;
          _modified = true;
          for (final t in set) {
            if (!tagService.tags.contains(t)) newTags.add(t);
          }
        }
      }
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
        title: const Text('Quality Check', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final t in _QcIssue.values)
                if (issues[t]!.isNotEmpty)
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
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
                            subtitle: Text(desc(t),
                                style: const TextStyle(color: Colors.white70)),
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
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
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
              _selectionMode ? '${_selected.length}' : widget.pack.name),
          actions: _selectionMode
              ? [
                  IconButton(onPressed: _deleteSelected, icon: const Icon(Icons.delete)),
                  IconButton(onPressed: _addTagDialog, icon: const Icon(Icons.label)),
                  IconButton(onPressed: _removeTagDialog, icon: const Icon(Icons.label_off)),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'all') {
                        setState(() => _selected
                            ..clear()
                            ..addAll(_hands));
                      } else {
                        _clearSelection();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'all', child: Text('Select All')),
                      PopupMenuItem(value: 'none', child: Text('Select None')),
                    ],
                  ),
                ]
              : [
                  SyncStatusIcon.of(context),
                  IconButton(
                    onPressed: _qualityCheck,
                    icon: const Icon(Icons.rule),
                    tooltip: 'Quality Check',
                  ),
                  IconButton(
                    onPressed: _importFromRoom,
                    icon: const Icon(Icons.playlist_add),
                  ),
                  IconButton(
                    onPressed: _hands.isEmpty ? null : _save,
                    icon: const Icon(Icons.check),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'snap') {
                        _saveSnapshot();
                      } else if (v == 'manage') {
                        _manageSnapshots();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'snap', child: Text('Save Snapshot')),
                      PopupMenuItem(
                          value: 'manage', child: Text('Manage Snapshots…')),
                    ],
                  )
                ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await _showAutoTagDialog();
            if (result != null) _autoTag(result.\$1, result.\$2);
          },
          child: const Icon(Icons.auto_fix_high),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Поиск'),
                onChanged: _setSearch,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<_SortOption>(
                value: _sort,
                underline: const SizedBox.shrink(),
                onChanged: (v) {
                  if (v != null) _setSort(v);
                },
                items: const [
                  DropdownMenuItem(value: _SortOption.newest, child: Text('Newest')),
                  DropdownMenuItem(value: _SortOption.oldest, child: Text('Oldest')),
                  DropdownMenuItem(value: _SortOption.position, child: Text('Hero Pos')),
                  DropdownMenuItem(value: _SortOption.tags, child: Text('Tags')),
                  DropdownMenuItem(value: _SortOption.mistakes, child: Text('Mistakes')),
                ],
              ),
            ),
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
                      onSelected: (_) => _setMistakeFilter(_MistakeFilter.any),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('0'),
                      selected: _mistakeFilter == _MistakeFilter.zero,
                      onSelected: (_) => _setMistakeFilter(_MistakeFilter.zero),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('1-2'),
                      selected: _mistakeFilter == _MistakeFilter.oneTwo,
                      onSelected: (_) => _setMistakeFilter(_MistakeFilter.oneTwo),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('3+'),
                      selected: _mistakeFilter == _MistakeFilter.threePlus,
                      onSelected: (_) => _setMistakeFilter(_MistakeFilter.threePlus),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                onReorder: (oldIndex, newIndex) {
                  final indices = _visibleIndices();
                  final oldGlobal = indices[oldIndex];
                  final newGlobal = indices[(newIndex > oldIndex ? newIndex - 1 : newIndex)];
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
                      title: Text(title),
                      subtitle:
                          hand.tags.isEmpty ? null : Text(hand.tags.join(', ')),
                      trailing: Container(
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
            )
          ],
        ),
      ),
    );
  }
}
