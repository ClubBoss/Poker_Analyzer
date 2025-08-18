import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../services/room_hand_history_importer.dart';
import '../services/training_pack_storage_service.dart';
import '../theme/app_colors.dart';
import 'room_hand_history_editor_screen.dart';
import '../widgets/saved_hand_viewer_dialog.dart';

enum _Filter { all, newOnly, dup }

class _Entry {
  final SavedHand hand;
  final bool duplicate;
  _Entry(this.hand, this.duplicate);
}

class RoomHandHistoryImportScreen extends StatefulWidget {
  final TrainingPack pack;
  const RoomHandHistoryImportScreen({super.key, required this.pack});

  @override
  State<RoomHandHistoryImportScreen> createState() =>
      _RoomHandHistoryImportScreenState();
}

class _RoomHandHistoryImportScreenState
    extends State<RoomHandHistoryImportScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late List<_Entry> _hands;
  late TrainingPack _pack;
  RoomHandHistoryImporter? _importer;
  final Set<SavedHand> _selected = {};
  _Filter _filter = _Filter.newOnly;
  List<SavedHand>? _undoHands;
  String? _tagFilter;

  bool get _selectionMode => _selected.isNotEmpty;
  bool get _undoActive => _undoHands != null;
  bool get _canAdd => _selectionMode && !_undoActive;
  Set<String> get _allTags {
    final tags = <String>{};
    for (final h in _pack.hands) {
      tags.addAll(h.tags);
    }
    for (final e in _hands) {
      tags.addAll(e.hand.tags);
    }
    return tags;
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

  @override
  void initState() {
    super.initState();
    _pack = widget.pack;
    _hands = [];
    RoomHandHistoryImporter.create().then((i) {
      if (mounted) setState(() => _importer = i);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() {});
    });
  }

  void _parse() {
    final text = _controller.text.trim();
    if (text.isEmpty || _importer == null) return;
    final parsed = _importer!.parse(text);
    final existing = <String>{for (final h in _pack.hands) h.name};
    final items = <_Entry>[];
    for (final h in parsed) {
      final dup = existing.contains(h.name);
      existing.add(h.name);
      items.add(_Entry(h, dup));
    }
    setState(() {
      _hands = items;
      _selected.clear();
      _searchController.clear();
      _filter = items.every((e) => e.duplicate) ? _Filter.dup : _Filter.newOnly;
      _tagFilter = null;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.isEmpty) return;
    setState(() => _controller.text = text);
    _parse();
  }

  Future<void> _preview(SavedHand hand) async {
    await showSavedHandViewerDialog(context, hand);
  }

  void _replaceHand(SavedHand oldHand, SavedHand newHand) {
    final i = _hands.indexWhere((e) => e.hand == oldHand);
    if (i != -1) {
      final dup = _hands[i].duplicate;
      setState(() {
        _hands[i] = _Entry(newHand, dup);
        if (_selected.remove(oldHand)) _selected.add(newHand);
      });
    }
  }

  Future<void> _editTags(SavedHand hand) async {
    final tags = hand.tags.toSet();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Tags', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 4,
                children: [
                  for (final tag in tags)
                    Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors
                          .primaries[tag.hashCode % Colors.primaries.length],
                      onDeleted: () => setStateDialog(() => tags.remove(tag)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (v) {
                  final input = v.text.toLowerCase();
                  if (input.isEmpty) return _allTags;
                  return _allTags.where((t) => t.toLowerCase().contains(input));
                },
                onSelected: (s) => setStateDialog(() => tags.add(s)),
                fieldViewBuilder: (context, controller, focusNode, _) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Add tag'),
                    onSubmitted: (v) {
                      final t = v.trim();
                      if (t.isNotEmpty) {
                        setStateDialog(() => tags.add(t));
                        controller.clear();
                      }
                    },
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
              onPressed: () => Navigator.pop(context, tags.toList()),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      _replaceHand(hand, hand.copyWith(tags: result));
    }
  }

  Future<void> _add(SavedHand hand) async {
    if (_undoActive) return;
    final updated = TrainingPack(
      name: _pack.name,
      description: _pack.description,
      category: _pack.category,
      gameType: _pack.gameType,
      colorTag: _pack.colorTag,
      isBuiltIn: _pack.isBuiltIn,
      tags: _pack.tags,
      hands: [..._pack.hands, hand],
      spots: _pack.spots,
      difficulty: _pack.difficulty,
      history: _pack.history,
    );
    await context.read<TrainingPackStorageService>().updatePack(_pack, updated);
    setState(() => _pack = updated);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomHandHistoryEditorScreen(pack: _pack, hands: [hand]),
      ),
    );
  }

  Future<void> _undoAdd() async {
    final hands = _undoHands;
    if (hands == null || hands.isEmpty) return;
    final updatedHands = List<SavedHand>.from(_pack.hands)
      ..removeWhere((h) => hands.any((u) => u.name == h.name));
    final updated = TrainingPack(
      name: _pack.name,
      description: _pack.description,
      category: _pack.category,
      gameType: _pack.gameType,
      colorTag: _pack.colorTag,
      isBuiltIn: _pack.isBuiltIn,
      tags: _pack.tags,
      hands: updatedHands,
      spots: _pack.spots,
      difficulty: _pack.difficulty,
      history: _pack.history,
    );
    await context.read<TrainingPackStorageService>().updatePack(_pack, updated);
    if (mounted) setState(() => _pack = updated);
    _undoHands = null;
  }

  Future<void> _addSelected() async {
    if (_undoActive) return;
    final unique = _selected
        .where((h) => !_pack.hands.any((e) => e.name == h.name))
        .toList();
    final count = unique.length;
    if (count == 0) return;
    final updated = TrainingPack(
      name: _pack.name,
      description: _pack.description,
      category: _pack.category,
      gameType: _pack.gameType,
      colorTag: _pack.colorTag,
      isBuiltIn: _pack.isBuiltIn,
      tags: _pack.tags,
      hands: [..._pack.hands, ...unique],
      spots: _pack.spots,
      difficulty: _pack.difficulty,
      history: _pack.history,
    );
    await context.read<TrainingPackStorageService>().updatePack(_pack, updated);
    if (!mounted) return;
    setState(() {
      _pack = updated;
      _selected.clear();
      _undoHands = unique;
    });
    final snack = SnackBar(
      content: Text('Added $count hands to pack'),
      action: SnackBarAction(label: 'Undo', onPressed: _undoAdd),
      duration: const Duration(seconds: 5),
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(snack);
    controller.closed.then((_) {
      if (mounted && _undoHands != null) setState(() => _undoHands = null);
    });
  }

  void _applyTagToSelected(String tag) {
    setState(() {
      for (final hand in _selected.toList()) {
        final tags = {...hand.tags, tag};
        _replaceHand(hand, hand.copyWith(tags: tags.toList()));
      }
    });
  }

  void _removeTagFromSelected(String tag) {
    setState(() {
      for (final hand in _selected.toList()) {
        if (hand.tags.contains(tag)) {
          final tags = List<String>.from(hand.tags)..remove(tag);
          _replaceHand(hand, hand.copyWith(tags: tags));
        }
      }
    });
  }

  List<_Entry> _filteredHands() {
    final query = _searchController.text.toLowerCase();
    return _hands.where((e) {
      if (_tagFilter != null && _tagFilter!.isNotEmpty) {
        if (!e.hand.tags.contains(_tagFilter)) return false;
      }
      switch (_filter) {
        case _Filter.newOnly:
          if (e.duplicate) return false;
          break;
        case _Filter.dup:
          if (!e.duplicate) return false;
          break;
        case _Filter.all:
          break;
      }
      if (query.isEmpty) return true;
      return e.hand.name.toLowerCase().contains(query);
    }).toList();
  }

  int get _hiddenDupCount {
    final visible = _filteredHands().where((e) => e.duplicate).length;
    final total = _hands.where((e) => e.duplicate).length;
    return total - visible;
  }

  @override
  Widget build(BuildContext context) {
    final hidden = _filter == _Filter.dup ? 0 : _hiddenDupCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(_pack.name),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() {
                if (v == 'select_all') {
                  _selected
                    ..clear()
                    ..addAll(_filteredHands().map((e) => e.hand));
                } else if (v == 'clear_selection') {
                  _selected.clear();
                }
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'select_all', child: Text('Select all')),
              PopupMenuItem(
                value: 'clear_selection',
                child: Text('Clear selection'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      bottomNavigationBar: _selectionMode || hidden > 0
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    if (_selectionMode) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canAdd ? _addSelected : null,
                          child: const Text('Add Selected'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.label_outline,
                          color: Colors.white,
                        ),
                        onSelected: (value) async {
                          if (value.startsWith('add:')) {
                            final tag = value.substring(4);
                            if (tag == '__new__') {
                              final c = TextEditingController();
                              final newTag = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.cardBackground,
                                  title: const Text(
                                    'New Tag',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: TextField(
                                    controller: c,
                                    autofocus: true,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, c.text.trim()),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              c.dispose();
                              if (newTag != null && newTag.isNotEmpty) {
                                _applyTagToSelected(newTag);
                              }
                            } else {
                              _applyTagToSelected(tag);
                            }
                          } else if (value.startsWith('remove:')) {
                            final tag = value.substring(7);
                            _removeTagFromSelected(tag);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              'Add Tag',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (final t in (_allTags.toList()..sort()))
                            PopupMenuItem(value: 'add:$t', child: Text(t)),
                          const PopupMenuItem(
                            value: 'add:__new__',
                            child: Text('New...'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              'Remove Tag',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (final t in (_allTags.toList()..sort()))
                            PopupMenuItem(value: 'remove:$t', child: Text(t)),
                        ],
                      ),
                    ],
                    if (hidden > 0) ...[
                      if (_selectionMode) const SizedBox(width: 12),
                      Text('Hidden duplicates: $hidden'),
                    ],
                  ],
                ),
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _paste,
        label: const Text('📋 Paste'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 6,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Hand history'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _parse, child: const Text('Parse')),
            const SizedBox(height: 12),
            if (_hands.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _tagFilter == null,
                      onSelected: (_) => setState(() => _tagFilter = null),
                    ),
                    const SizedBox(width: 8),
                    for (final tag in (_allTags.toList()..sort())) ...[
                      ChoiceChip(
                        label: Text(tag),
                        selected: _tagFilter == tag,
                        backgroundColor: Colors
                            .primaries[tag.hashCode % Colors.primaries.length]
                            .withValues(alpha: 0.3),
                        selectedColor: Colors
                            .primaries[tag.hashCode % Colors.primaries.length],
                        onSelected: (_) => setState(() => _tagFilter = tag),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (_hands.isNotEmpty)
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == _Filter.all,
                    onSelected: (_) => setState(() => _filter = _Filter.all),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('New'),
                    selected: _filter == _Filter.newOnly,
                    onSelected: (_) =>
                        setState(() => _filter = _Filter.newOnly),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Duplicates'),
                    selected: _filter == _Filter.dup,
                    onSelected: (_) => setState(() => _filter = _Filter.dup),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search',
                      ),
                      onChanged: (_) => _onSearchChanged(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _hands.isEmpty
                  ? const Center(child: Text('No hands'))
                  : Builder(
                      builder: (context) {
                        final list = _filteredHands();
                        final content = list.isEmpty
                            ? const Center(child: Text('No hands found'))
                            : ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final entry = list[i];
                                  final h = entry.hand;
                                  return Card(
                                    color: entry.duplicate
                                        ? AppColors.errorBg
                                        : AppColors.cardBackground,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      leading: IgnorePointer(
                                        ignoring: _undoActive,
                                        child: Checkbox(
                                          value: _selected.contains(h),
                                          onChanged: (_) => _toggleSelect(h),
                                        ),
                                      ),
                                      title: Text(
                                        h.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${h.heroPosition} • ${h.numberOfPlayers}p',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Builder(
                                            builder: (_) {
                                              final hero =
                                                  h.playerCards.length >
                                                      h.heroIndex
                                                  ? h.playerCards[h.heroIndex]
                                                        .map(
                                                          (c) => c.toString(),
                                                        )
                                                        .join(' ')
                                                  : '';
                                              final board = h.boardCards
                                                  .map((c) => c.toString())
                                                  .join(' ');
                                              if (hero.isEmpty && board.isEmpty)
                                                return const SizedBox.shrink();
                                              final text = hero.isEmpty
                                                  ? board
                                                  : '$hero  $board';
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2,
                                                ),
                                                child: Text(
                                                  text,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          if (h.tags.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Wrap(
                                                spacing: 4,
                                                children: [
                                                  for (final t in h.tags)
                                                    Chip(
                                                      label: Text(
                                                        t,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          Colors.primaries[t
                                                                  .hashCode %
                                                              Colors
                                                                  .primaries
                                                                  .length],
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: IgnorePointer(
                                        ignoring: _undoActive,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_red_eye,
                                                color: Colors.white70,
                                              ),
                                              onPressed: () => _preview(h),
                                            ),
                                            IconButton(
                                              icon: const Text(
                                                '🏷️',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                              onPressed: () => _editTags(h),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                color: Colors.white70,
                                              ),
                                              onPressed: () => _add(h),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                        return Stack(
                          children: [
                            content,
                            if (_undoActive)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
