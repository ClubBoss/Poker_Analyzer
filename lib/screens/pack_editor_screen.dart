import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tag_service.dart';
import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../services/training_pack_storage_service.dart';
import 'room_hand_history_import_screen.dart';
import 'room_hand_history_editor_screen.dart';
import '../widgets/sync_status_widget.dart';

enum _SortOption { newest, oldest, position, tags, mistakes }

class PackEditorScreen extends StatefulWidget {
  final TrainingPack pack;
  const PackEditorScreen({super.key, required this.pack});

  @override
  State<PackEditorScreen> createState() => _PackEditorScreenState();
}

class _PackEditorScreenState extends State<PackEditorScreen> {
  static const _sortKey = 'pack_editor_sort';
  static const _searchKey = 'pack_editor_search';

  late List<SavedHand> _hands;
  bool _modified = false;
  SavedHand? _removed;
  int _removedIndex = -1;
  final Set<SavedHand> _selected = {};
  bool get _selectionMode => _selected.isNotEmpty;
  final TextEditingController _searchController = TextEditingController();

  _SortOption _sort = _SortOption.newest;

  @override
  void initState() {
    super.initState();
    _hands = List.from(widget.pack.hands);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sort = _SortOption.values[prefs.getInt(_sortKey) ?? 0];
      _searchController.text = prefs.getString(_searchKey) ?? '';
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
          builder: (_) => RoomHandHistoryImportScreen(pack: widget.pack)),
    );
    final updated = context
        .read<TrainingPackStorageService>()
        .packs
        .firstWhere((p) => p.id == widget.pack.id, orElse: () => widget.pack);
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
              RoomHandHistoryEditorScreen(pack: widget.pack, hands: [hand])),
    );
    final updated = context
        .read<TrainingPackStorageService>()
        .packs
        .firstWhere((p) => p.id == widget.pack.id, orElse: () => widget.pack);
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
      tags: widget.pack.tags,
      hands: _hands,
      spots: widget.pack.spots,
      difficulty: widget.pack.difficulty,
    );
    await context
        .read<TrainingPackStorageService>()
        .updatePack(widget.pack, updated);
    if (mounted) Navigator.pop(context, true);
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
                    onPressed: _importFromRoom,
                    icon: const Icon(Icons.playlist_add),
                  ),
                  IconButton(
                    onPressed: _hands.isEmpty ? null : _save,
                    icon: const Icon(Icons.check),
                  )
                ],
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
