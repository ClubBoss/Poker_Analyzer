import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/saved_hand_stats_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../helpers/category_translations.dart';
import '../screens/training_session_screen.dart';

class TopCategoriesDrillCard extends StatelessWidget {
  const TopCategoriesDrillCard({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context
        .watch<SavedHandStatsService>()
        .getTopMistakeCategories(limit: 3);
    if (list.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: accent),
              const SizedBox(width: 8),
              const Text(
                'Топ слабые категории',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in list)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${translateCategory(e.key)} • -${e.value.toStringAsFixed(1)} EV',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final tpl = await TrainingPackService.createDrillFromCategory(
                          context, e.key);
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
            )
        ],
      ),
    );
  }
}
