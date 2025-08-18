import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class RepeatLastCorrectedCard extends StatelessWidget {
  const RepeatLastCorrectedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final hand = hands.reversed.firstWhereOrNull((h) => h.corrected);
    if (hand == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final cat = hand.category ?? 'Без категории';
    final ev = hand.evLossRecovered ?? 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${ev.toStringAsFixed(1)} EV восстановлено',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final tpl = await TrainingPackService.createRepeatForCorrected(
                context,
              );
              if (tpl == null) return;
              await context.read<TrainingSessionService>().startSession(tpl);
              if (context.mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TrainingSessionScreen(),
                  ),
                );
              }
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
