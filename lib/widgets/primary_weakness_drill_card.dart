import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/category_translations.dart';
import '../services/saved_hand_stats_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class PrimaryWeaknessDrillCard extends StatelessWidget {
  const PrimaryWeaknessDrillCard({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.watch<SavedHandStatsService>().getTopMistakeCategories(
          limit: 1,
        );
    if (list.isEmpty) return const SizedBox.shrink();
    final entry = list.first;
    final accent = Theme.of(context).colorScheme.secondary;
    final name = translateCategory(entry.key).isEmpty
        ? 'Без категории'
        : translateCategory(entry.key);
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
              Icon(Icons.warning, color: accent),
              const SizedBox(width: 8),
              const Text(
                'Главная слабость',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            '-${entry.value.toStringAsFixed(1)} EV',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final session = context.read<TrainingSessionService>();
                final tpl = await TrainingPackService.createDrillFromCategory(
                  context,
                  entry.key,
                );
                if (tpl == null) return;
                await session.startSession(tpl);
                if (context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrainingSessionScreen(),
                    ),
                  );
                }
              },
              child: const Text('Начать тренировку'),
            ),
          ),
        ],
      ),
    );
  }
}
