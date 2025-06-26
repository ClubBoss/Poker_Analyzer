import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        title: const Text('История раздач'),
        centerTitle: true,
        bottom: PreferredSize(
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
                  showGameFilters: false,
                ),
                SavedHandListView(
                  hands: filteredFav,
                  title: 'Избранные',
                  onTap: _openHand,
                  onFavoriteToggle: (hand) => _toggleFavorite(hand, manager),
                  showGameFilters: false,
                ),
                SavedHandListView(
                  hands: filteredSessions,
                  title: 'Сессии',
                  onTap: _openHand,
                  onFavoriteToggle: (hand) => _toggleFavorite(hand, manager),
                  showGameFilters: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
