import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_storage_service.dart';
import '../theme/constants.dart';
import '../widgets/saved_hand_tile.dart';
import '../widgets/saved_hand_detail_sheet.dart';

class SavedHandsScreen extends StatefulWidget {
  const SavedHandsScreen({super.key});

  @override
  State<SavedHandsScreen> createState() => _SavedHandsScreenState();
}

class _SavedHandsScreenState extends State<SavedHandsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _tagFilter = 'Все';
  String _positionFilter = 'Все';
  String _dateFilter = 'Все';
  bool _onlyFavorites = false;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<SavedHandStorageService>();
    final allHands = storage.hands;
    final tags = <String>{for (final h in allHands) ...h.tags};
    final positions = <String>{for (final h in allHands) h.heroPosition};

    List<SavedHand> visible = allHands.where((hand) {
      if (_onlyFavorites && !hand.isFavorite) return false;
      if (_tagFilter != 'Все' && !hand.tags.contains(_tagFilter)) return false;
      if (_positionFilter != 'Все' && hand.heroPosition != _positionFilter) {
        return false;
      }
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
                IconButton(
                  onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
                  icon: Icon(_onlyFavorites ? Icons.star : Icons.star_border),
                  color: _onlyFavorites ? Colors.amber : Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Text('Нет сохранённых раздач.',
                        style: TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.padding16),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final hand = visible[index];
                      final originalIndex = allHands.indexOf(hand);
                      return SavedHandTile(
                        hand: hand,
                        onFavoriteToggle: () {
                          final updated = hand.copyWith(isFavorite: !hand.isFavorite);
                          storage.update(originalIndex, updated);
                        },
                        onTap: () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.grey[900],
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (_) => SavedHandDetailSheet(
                              hand: hand,
                              onDelete: () {
                                Navigator.pop(context);
                                storage.removeAt(originalIndex);
                              },
                              onExportJson: () => _exportJson(hand),
                              onExportCsv: () => _exportCsv(hand),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson(SavedHand hand) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${hand.name}_${hand.date.millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonEncode(hand.toJson()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Файл сохранён: $fileName')),
    );
    OpenFile.open(file.path);
  }

  Future<void> _exportCsv(SavedHand hand) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${hand.name}_${hand.date.millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    final buffer = StringBuffer()
      ..writeln('name,heroPosition,date,isFavorite,tags,comment')
      ..writeln(
          '${hand.name},${hand.heroPosition},${hand.date.toIso8601String()},${hand.isFavorite},"${hand.tags.join('|')}","${hand.comment ?? ''}"');
    await file.writeAsString(buffer.toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Файл сохранён: $fileName')),
    );
    OpenFile.open(file.path);
  }
}
