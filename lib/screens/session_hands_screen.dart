import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../widgets/saved_hand_tile.dart';
import '../helpers/date_utils.dart';
import '../theme/app_colors.dart';
import '../theme/constants.dart';
import 'hand_history_review_screen.dart';

class SessionHandsScreen extends StatelessWidget {
  final int sessionId;

  const SessionHandsScreen({super.key, required this.sessionId});

  String _actionType(SavedHand hand) {
    final expected = hand.expectedAction?.trim().toLowerCase();
    final gto = hand.gtoAction?.trim().toLowerCase();
    if (expected != null && gto != null && expected != gto) {
      return 'Error';
    }
    if (expected == null || expected.isEmpty) return 'Other';
    if (expected.contains('push')) return 'Push';
    if (expected.contains('call')) return 'Call';
    if (expected.contains('fold')) return 'Fold';
    return 'Other';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}ч');
    parts.add('${minutes}м');
    return parts.join(' ');
  }

  Widget _buildSummary(List<SavedHand> hands) {
    final start = hands.last.savedAt;
    final end = hands.first.savedAt;
    final duration = end.difference(start);
    int correct = 0;
    int incorrect = 0;
    for (final h in hands) {
      final expected = h.expectedAction;
      final gto = h.gtoAction;
      if (expected != null && gto != null) {
        if (expected.trim().toLowerCase() == gto.trim().toLowerCase()) {
          correct++;
        } else {
          incorrect++;
        }
      }
    }

    final totalDecisions = correct + incorrect;
    final winrate =
        totalDecisions > 0 ? (correct / totalDecisions * 100).toStringAsFixed(1) : null;
    final ev = correct - incorrect;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.padding16, vertical: 8),
      child: Card(
        color: AppColors.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Раздач: ${hands.length}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text('Начало: ${formatDateTime(start)}',
                  style: const TextStyle(color: Colors.white)),
              Text('Конец: ${formatDateTime(end)}',
                  style: const TextStyle(color: Colors.white)),
              Text('Длительность: ${_formatDuration(duration)}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text('Верно: $correct • Ошибки: $incorrect',
                  style: const TextStyle(color: Colors.white)),
              if (winrate != null) ...[
                const SizedBox(height: 4),
                Text('Winrate: $winrate% • EV: ${ev >= 0 ? '+' : ''}$ev',
                    style: const TextStyle(color: Colors.white)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final path = await manager.exportSessionHandsMarkdown(sessionId);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'session_${sessionId}.md');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: session_${sessionId}.md')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final path = await manager.exportSessionHandsPdf(sessionId);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'session_${sessionId}.pdf');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: session_${sessionId}.pdf')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final hands = manager.hands
        .where((h) => h.sessionId == sessionId)
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

    Widget _buildGroupedList() {
      final groups = <String, List<SavedHand>>{
        'Push': [],
        'Call': [],
        'Fold': [],
        'Error': [],
        'Other': [],
      };
      for (final h in hands) {
        groups[_actionType(h)]!.add(h);
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in groups.entries)
            if (entry.value.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              for (final hand in entry.value)
                SavedHandTile(
                  hand: hand,
                  onFavoriteToggle: () {
                    final originalIndex = manager.hands.indexOf(hand);
                    final updated = hand.copyWith(isFavorite: !hand.isFavorite);
                    manager.update(originalIndex, updated);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HandHistoryReviewScreen(hand: hand),
                      ),
                    );
                  },
                ),
            ]
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Сессия $sessionId'),
        centerTitle: true,
      ),
      body: hands.isEmpty
          ? const Center(
              child: Text(
                'Нет раздач в этой сессии',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _exportMarkdown(context),
                          child: const Text('Экспорт в Markdown'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _exportPdf(context),
                          child: const Text('Экспорт в PDF'),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSummary(hands),
                Expanded(child: _buildGroupedList()),
              ],
            ),
    );
  }
}
