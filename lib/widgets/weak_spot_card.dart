import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/weak_spot_recommendation_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class WeakSpotCard extends StatelessWidget {
  const WeakSpotCard({super.key});

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<WeakSpotRecommendationService>().recommendation;
    if (rec == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Рекомендация',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${rec.position} — ${rec.mistakes} ошибок',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final tpl = await context
                  .read<WeakSpotRecommendationService>()
                  .buildPack();
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
