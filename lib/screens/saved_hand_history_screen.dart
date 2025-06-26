import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../theme/app_colors.dart';
import '../theme/constants.dart';
import '../widgets/saved_hand_list_view.dart';
import 'hand_history_review_screen.dart';

class SavedHandHistoryScreen extends StatefulWidget {
  const SavedHandHistoryScreen({super.key});

  @override
  State<SavedHandHistoryScreen> createState() => _SavedHandHistoryScreenState();
}

class _SavedHandHistoryScreenState extends State<SavedHandHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  String _gameTypeFilter = 'Все';
  String _categoryFilter = 'Все';
  final Set<SavedHand> _selected = {};

  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<SavedHand> _applyFilters(Iterable<SavedHand> hands) {
    return [
      for (final h in hands)
        if ((_gameTypeFilter == 'Все' || h.gameType == _gameTypeFilter) &&
            (_categoryFilter == 'Все' || h.category == _categoryFilter))
          h
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  void _openHand(SavedHand hand) {
    if (_selectionMode) {
      _toggleSelect(hand);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HandHistoryReviewScreen(hand: hand),
      ),
    );
  }

  void _toggleFavorite(SavedHand hand, SavedHandManagerService manager) {
    final index = manager.hands.indexOf(hand);
    final updated = hand.copyWith(isFavorite: !hand.isFavorite);
    manager.update(index, updated);
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

  Future<void> _deleteSelected(SavedHandManagerService manager) async {
    final indices = _selected
        .map((h) => manager.hands.indexOf(h))
        .where((i) => i != -1)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    for (final i in indices) {
      await manager.removeAt(i);
    }
    _clearSelection();
  }

  Future<void> _favoriteSelected(SavedHandManagerService manager) async {
    if (_selected.isEmpty) return;
    final add = !_selected.every((h) => h.isFavorite);
    for (final h in _selected) {
      final idx = manager.hands.indexOf(h);
      if (idx == -1) continue;
      await manager.update(idx, h.copyWith(isFavorite: add));
    }
    _clearSelection();
  }

  Future<void> _exportSelected(SavedHandManagerService manager) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('JSON'),
            onTap: () => Navigator.pop(context, 'json'),
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Markdown'),
            onTap: () => Navigator.pop(context, 'md'),
          ),
        ],
      ),
    );
    if (format == null) return;
    String? path;
    if (format == 'json') {
      path = await manager.exportHandsJson(_selected.toList());
    } else {
      path = await manager.exportHandsMarkdown(_selected.toList());
    }
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: path.split(Platform.pathSeparator).last);
    if (mounted) {
      final name = path.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Файл сохранён: $name')));
    }
    _clearSelection();
  }

  Future<void> _renameHand(
      SavedHand hand, SavedHandManagerService manager) async {
    final controller = TextEditingController(text: hand.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title:
            const Text('Переименовать', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && name != hand.name) {
      final index = manager.hands.indexOf(hand);
      await manager.update(index, hand.copyWith(name: name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final allHands = manager.hands;
    final gameTypes = {
      for (final h in allHands)
        if (h.gameType != null && h.gameType!.isNotEmpty) h.gameType!
    };
    final categories = {
      for (final h in allHands)
        if (h.category != null && h.category!.isNotEmpty) h.category!
    };

    final filteredAll = _applyFilters(allHands);
    final filteredFav = _applyFilters(allHands.where((h) => h.isFavorite));
    final filteredSessions = _applyFilters(allHands);

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _clearSelection,
              )
            : null,
        title: _selectionMode
            ? Text('Выбрано ${_selected.length}')
            : const Text('История раздач'),
        centerTitle: true,
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteSelected(manager),
                ),
                IconButton(
                  icon: const Icon(Icons.star),
                  onPressed: () => _favoriteSelected(manager),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _exportSelected(manager),
                ),
              ]
            : null,
        bottom: _selectionMode
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppConstants.radius8),
                    ),
                    child: TabBar(
                      controller: _controller,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.white70,
                      indicator: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(AppConstants.radius8),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: EdgeInsets.zero,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Все'),
                        Tab(text: 'Избранные'),
                        Tab(text: 'Сессии'),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      body: Column(
        children: [
          if (gameTypes.isNotEmpty || categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppConstants.padding16),
              child: Row(
                children: [
                  if (gameTypes.isNotEmpty)
                    DropdownButton<String>(
                      value: _gameTypeFilter,
                      dropdownColor: const Color(0xFF2A2B2E),
                      onChanged: (v) =>
                          setState(() => _gameTypeFilter = v ?? 'Все'),
                      items: ['Все', ...gameTypes]
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                    ),
                  if (gameTypes.isNotEmpty && categories.isNotEmpty)
                    const SizedBox(width: 12),
                  if (categories.isNotEmpty)
                    DropdownButton<String>(
                      value: _categoryFilter,
                      dropdownColor: const Color(0xFF2A2B2E),
                      onChanged: (v) =>
                          setState(() => _categoryFilter = v ?? 'Все'),
                      items: ['Все', ...categories]
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                    ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: [
                SavedHandListView(
                  hands: filteredAll,
                  title: 'Раздачи',
                  onTap: _openHand,
                  onFavoriteToggle: (hand) => _toggleFavorite(hand, manager),
                  onRename: (hand) => _renameHand(hand, manager),
                  showGameFilters: false,
                  selected: _selected,
                  selectionMode: _selectionMode,
                  onToggleSelection: _toggleSelect,
                ),
                SavedHandListView(
                  hands: filteredFav,
                  title: 'Избранные',
                  onTap: _openHand,
                  onFavoriteToggle: (hand) => _toggleFavorite(hand, manager),
                  onRename: (hand) => _renameHand(hand, manager),
                  showGameFilters: false,
                  selected: _selected,
                  selectionMode: _selectionMode,
                  onToggleSelection: _toggleSelect,
                ),
                SavedHandListView(
                  hands: filteredSessions,
                  title: 'Сессии',
                  onTap: _openHand,
                  onFavoriteToggle: (hand) => _toggleFavorite(hand, manager),
                  onRename: (hand) => _renameHand(hand, manager),
                  showGameFilters: false,
                  selected: _selected,
                  selectionMode: _selectionMode,
                  onToggleSelection: _toggleSelect,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
