import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class RepeatCorrectedDrillCard extends StatelessWidget {
  const RepeatCorrectedDrillCard({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final list = [
      for (final h in hands)
        if (h.corrected && (h.evLoss?.abs() ?? 0) >= 1.0) h,
    ];
    if (list.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Повтор исправленных',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${list.length} раздач',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final tpl =
                  await TrainingPackService.createDrillFromCorrectedHands(
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
            child: const Text('Тренировать'),
          ),
        ],
      ),
    );
  }
}
