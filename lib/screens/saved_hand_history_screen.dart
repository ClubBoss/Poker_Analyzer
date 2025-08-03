import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/saved_hand_list_view.dart';
import '../widgets/saved_hand_viewer_dialog.dart';
import '../widgets/sync_status_widget.dart';

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
  DateTime? _fromDate;
  DateTime? _toDate;

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
            (_categoryFilter == 'Все' || h.category == _categoryFilter) &&
            (_fromDate == null || !h.date.isBefore(_fromDate!)) &&
            (_toDate == null || !h.date.isAfter(_toDate!)))
          h
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  void _openHand(SavedHand hand) {
    showSavedHandViewerDialog(context, hand);
  }

  void _toggleFavorite(SavedHand hand, SavedHandManagerService manager) {
    final index = manager.hands.indexOf(hand);
    final updated = hand.copyWith(isFavorite: !hand.isFavorite);
    manager.update(index, updated);
  }

  String _dateStr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

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
        actions: [SyncStatusIcon.of(context)],
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
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_fromDate == null && _toDate == null
                        ? 'Период'
                        : '${_fromDate == null ? '…' : _dateStr(_fromDate!)} – ${_toDate == null ? '…' : _dateStr(_toDate!)}'),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _fromDate == null && _toDate == null
                            ? null
                            : DateTimeRange(
                                start: _fromDate ??
                                    DateTime.now().subtract(const Duration(days: 30)),
                                end: _toDate ?? DateTime.now(),
                              ),
                      );
                      if (picked != null) {
                        setState(() {
                          _fromDate = picked.start;
                          _toDate = picked.end;
                        });
                      }
                    },
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
                ),
                SavedHandListView(
                  hands: filteredFav,
                  title: 'Избранные',
                  onTap: _openHand,
                  onFavoriteToggle: (hand) => _toggleFavorite(hand, manager),
                  onRename: (hand) => _renameHand(hand, manager),
                  showGameFilters: false,
                ),
                SavedHandListView(
                  hands: filteredSessions,
                  title: 'Сессии',
                  onTap: _openHand,
                  onFavoriteToggle: (hand) => _toggleFavorite(hand, manager),
                  onRename: (hand) => _renameHand(hand, manager),
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
