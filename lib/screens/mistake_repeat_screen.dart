import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import 'hand_history_review_screen.dart';
import '../widgets/saved_hand_tile.dart';

class MistakeRepeatScreen extends StatelessWidget {
  const MistakeRepeatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final Map<String, List<SavedHand>> grouped = {};

    for (final h in hands) {
      final expected = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (expected != null &&
          gto != null &&
          expected.isNotEmpty &&
          gto.isNotEmpty &&
          expected != gto) {
        for (final tag in h.tags) {
          grouped.putIfAbsent(tag, () => []).add(h);
        }
      }
    }

    final entries = grouped.entries
        .where((e) => e.value.length > 1)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Повторы ошибок'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${entry.value.length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                for (final hand in entry.value)
                  SavedHandTile(
                    hand: hand,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HandHistoryReviewScreen(hand: hand),
                        ),
                      );
                    },
                    onFavoriteToggle: () {
                      final manager =
                          context.read<SavedHandManagerService>();
                      final idx = manager.hands.indexOf(hand);
                      manager.update(idx, hand.copyWith(isFavorite: !hand.isFavorite));
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
