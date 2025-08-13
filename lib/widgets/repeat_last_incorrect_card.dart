import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class RepeatLastIncorrectCard extends StatelessWidget {
  const RepeatLastIncorrectCard({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final hand = hands.reversed.firstWhereOrNull((h) {
      final ev = h.evLoss ?? 0.0;
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      return ev.abs() >= 1.0 &&
          !h.corrected &&
          exp != null &&
          gto != null &&
          exp != gto;
    });
    if (hand == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final cat = hand.category ?? 'Без категории';
    final ev = hand.evLoss?.abs() ?? 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.replay, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Повторить раздачу',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(cat, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                Text('-${ev.toStringAsFixed(1)} EV',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final tpl =
                  await TrainingPackService.createRepeatForIncorrect(context);
              if (tpl == null) return;
              await context.read<TrainingSessionService>().startSession(tpl);
              if (context.mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrainingSessionScreen()),
                );
              }
            },
            child: const Text('Тренировать'),
          ),
        ],
      ),
    );
  }
}
