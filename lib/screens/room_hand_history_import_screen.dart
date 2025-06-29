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

  bool get _selectionMode => _selected.isNotEmpty;
  bool get _undoActive => _undoHands != null;
  bool get _canAdd => _selectionMode && !_undoActive;

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
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(hand.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
          builder: (_) =>
              RoomHandHistoryEditorScreen(pack: _pack, hands: [hand])),
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
    final controller = ScaffoldMessenger.of(context).showSnackBar(snack);
    controller.closed.then((_) {
      if (mounted && _undoHands != null) setState(() => _undoHands = null);
    });
  }

  List<_Entry> _filteredHands() {
    final query = _searchController.text.toLowerCase();
    return _hands.where((e) {
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
              PopupMenuItem(value: 'clear_selection', child: Text('Clear selection')),
            ],
          )
        ],
      ),
      backgroundColor: AppColors.background,
      bottomNavigationBar: _selectionMode || hidden > 0
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    if (_selectionMode)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canAdd ? _addSelected : null,
                          child: const Text('Add Selected'),
                        ),
                      ),
                    if (hidden > 0) ...[
                      if (_selectionMode) const SizedBox(width: 12),
                      Text('Hidden duplicates: $hidden'),
                    ]
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
                          prefixIcon: Icon(Icons.search), hintText: 'Search'),
                      onChanged: (_) => _onSearchChanged(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _hands.isEmpty
                  ? const Center(child: Text('No hands'))
                  : Builder(builder: (context) {
                      final list = _filteredHands();
                      return list.isEmpty
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
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    leading: IgnorePointer(
                                      ignoring: _undoActive,
                                      child: Checkbox(
                                        value: _selected.contains(h),
                                        onChanged: (_) => _toggleSelect(h),
                                      ),
                                    ),
                                    title: Text(h.name,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    subtitle: Text(
                                        '${h.heroPosition} • ${h.numberOfPlayers}p',
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                    trailing: IgnorePointer(
                                      ignoring: _undoActive,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.remove_red_eye,
                                                color: Colors.white70),
                                            onPressed: () => _preview(h),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add,
                                                color: Colors.white70),
                                            onPressed: () => _add(h),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                    }),
            ),
          ],
        ),
      ),
    );
  }
}
