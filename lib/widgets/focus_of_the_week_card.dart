import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/evaluation_executor_service.dart';
import '../helpers/poker_street_helper.dart';
import '../models/saved_hand.dart';
import 'saved_hand_list_view.dart';
import '../screens/hand_history_review_screen.dart';
import '../screens/training_screen.dart';
import 'sync_status_widget.dart';

class FocusOfTheWeekCard extends StatelessWidget {
  const FocusOfTheWeekCard({super.key});

  Map<String, Map<String, int>> _counts(List<SavedHand> hands) {
    final map = <String, Map<String, int>>{};
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    for (final h in hands) {
      if (h.date.isBefore(cutoff)) continue;
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null && exp != gto) {
        final pos = h.heroPosition;
        final street = streetName(h.boardStreet);
        map.putIfAbsent(pos, () => {});
        map[pos]![street] = (map[pos]![street] ?? 0) + 1;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    context.read<EvaluationExecutorService>();
    final counts = _counts(manager.hands);
    String? pos;
    String? street;
    int max = 0;
    for (final e in counts.entries) {
      for (final s in e.value.entries) {
        if (s.value > max) {
          pos = e.key;
          street = s.key;
          max = s.value;
        }
      }
    }
    if (max <= 3 || pos == null || street == null)
      return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Фокус недели',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('$pos • $street — $max ошибок',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _FocusMistakeHandsScreen(
                    position: pos!,
                    street: street!,
                  ),
                ),
              );
            },
            child: const Text('Тренировать'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final manager = context.read<SavedHandManagerService>();
              final cutoff = DateTime.now().subtract(const Duration(days: 7));
              final filteredHands = [
                for (final h in manager.hands)
                  if (h.heroPosition == pos! &&
                      streetName(h.boardStreet) == street! &&
                      h.date.isAfter(cutoff))
                    h
              ];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingScreen.drill(
                    hands: filteredHands,
                    anteBb: 0,
                  ),
                ),
              );
            },
            child: const Text('Начать сессию'),
          ),
        ],
      ),
    );
  }
}

class _FocusMistakeHandsScreen extends StatelessWidget {
  final String position;
  final String street;
  const _FocusMistakeHandsScreen(
      {required this.position, required this.street});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final filtered = [
      for (final h in hands)
        if (h.heroPosition == position &&
            streetName(h.boardStreet) == street &&
            h.date.isAfter(cutoff))
          h
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('$position • $street'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: SavedHandListView(
        hands: filtered,
        positions: [position],
        initialAccuracy: 'errors',
        filterKey: street,
        title: 'Ошибки: $position / $street',
        onTap: (hand) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HandHistoryReviewScreen(hand: hand),
            ),
          );
        },
      ),
    );
  }
}
