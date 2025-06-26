import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/saved_hand_import_export_service.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/constants.dart';
import '../widgets/saved_hand_list_view.dart';
import '../screens/hand_history_review_screen.dart';

class SavedHandsScreen extends StatefulWidget {
  final String? initialTag;
  final String? initialPosition;
  final String? initialAccuracy;
  final String? initialDateFilter;

  const SavedHandsScreen({
    super.key,
    this.initialTag,
    this.initialPosition,
    this.initialAccuracy,
    this.initialDateFilter,
  });

  @override
  State<SavedHandsScreen> createState() => _SavedHandsScreenState();
}

class _SavedHandsScreenState extends State<SavedHandsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _tagFilter = 'Все';
  String _positionFilter = 'Все';
  String _dateFilter = 'Все';
  String _accuracyFilter = 'Все';
  bool _onlyFavorites = false;
  late SavedHandImportExportService _importExport;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    _tagFilter = widget.initialTag ?? 'Все';
    _positionFilter = widget.initialPosition ?? 'Все';
    _accuracyFilter = widget.initialAccuracy ?? 'Все';
    _dateFilter = widget.initialDateFilter ?? 'Все';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final manager = context.read<SavedHandManagerService>();
    _importExport = SavedHandImportExportService(manager);
  }

  @override
  Widget build(BuildContext context) {
    final handManager = context.watch<SavedHandManagerService>();
    final allHands = handManager.hands;
    final tags = <String>{for (final h in allHands) ...h.tags};
    final positions = <String>{for (final h in allHands) h.heroPosition};

    List<SavedHand> visible = allHands.where((hand) {
      if (_onlyFavorites && !hand.isFavorite) return false;
      final now = DateTime.now();
      if (_dateFilter == 'Сегодня' && !_sameDay(hand.date, now)) return false;
      if (_dateFilter == '7 дней' && hand.date.isBefore(now.subtract(const Duration(days: 7)))) {
        return false;
      }
      if (_dateFilter == '30 дней' && hand.date.isBefore(now.subtract(const Duration(days: 30)))) {
        return false;
      }
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        final inTags = hand.tags.any((t) => t.toLowerCase().contains(query));
        final inComment = hand.comment?.toLowerCase().contains(query) ?? false;
        final inPos = hand.heroPosition.toLowerCase().contains(query);
        if (!(inTags || inComment || inPos)) return false;
      }
      return true;
    }).toList();

    visible.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сохранённые раздачи'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.padding16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding16),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _tagFilter,
                  dropdownColor: const Color(0xFF2A2B2E),
                  onChanged: (v) => setState(() => _tagFilter = v ?? 'Все'),
                  items: ['Все', ...tags]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _positionFilter,
                  dropdownColor: const Color(0xFF2A2B2E),
                  onChanged: (v) => setState(() => _positionFilter = v ?? 'Все'),
                  items: ['Все', ...positions]
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _dateFilter,
                  dropdownColor: const Color(0xFF2A2B2E),
                  onChanged: (v) => setState(() => _dateFilter = v ?? 'Все'),
                  items: ['Все', 'Сегодня', '7 дней', '30 дней']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _accuracyFilter,
                  dropdownColor: const Color(0xFF2A2B2E),
                  onChanged: (v) => setState(() => _accuracyFilter = v ?? 'Все'),
                  items: ['Все', 'Только ошибки', 'Только верные']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                ),
                IconButton(
                  onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
                  icon: Icon(_onlyFavorites ? Icons.star : Icons.star_border),
                  color: _onlyFavorites ? Colors.amber : Colors.white,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed:
                      handManager.hands.isEmpty ? null : _exportArchive,
                  child: const Text('Экспорт архива'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SavedHandListView(
              hands: visible,
              title: 'Раздачи',
              tags: _tagFilter != 'Все' ? [_tagFilter] : null,
              positions: _positionFilter != 'Все' ? [_positionFilter] : null,
              initialAccuracy: _accuracyFilter == 'Только верные'
                  ? 'correct'
                  : _accuracyFilter == 'Только ошибки'
                      ? 'errors'
                      : null,
              showAccuracyToggle: false,
              onTap: (hand) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HandHistoryReviewScreen(hand: hand),
                  ),
                );
              },
              onFavoriteToggle: (hand) {
                final originalIndex = allHands.indexOf(hand);
                final updated = hand.copyWith(isFavorite: !hand.isFavorite);
                handManager.update(originalIndex, updated);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson(SavedHand hand) async {
    await _importExport.exportJsonFile(context, hand);
  }

  Future<void> _exportCsv(SavedHand hand) async {
    await _importExport.exportCsvFile(context, hand);
  }

  Future<void> _exportArchive() async {
    final manager = context.read<SavedHandManagerService>();
    final path = await manager.exportSessionsArchive();
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'saved_hands_archive.zip');
    if (context.mounted) {
      final name = path.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Файл сохранён: $name')));
    }
  }
}
