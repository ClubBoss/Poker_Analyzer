import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/weak_spot_recommendation_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class WeakSpotCard extends StatelessWidget {
  const WeakSpotCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WeakSpotRecommendationService>();
    final recs = service.recommendations;
    if (recs.isEmpty) return const SizedBox.shrink();
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
          const Row(
            children: [
              Icon(Icons.school, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Слабые места',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final r in recs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${r.position.label} • ${(r.accuracy * 100).toStringAsFixed(1)}% • EV ${r.ev.toStringAsFixed(1)} • ICM ${r.icm.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final tpl = await service.buildPack(r.position);
                      if (tpl == null) return;
                      await context.read<TrainingSessionService>().startSession(
                        tpl,
                      );
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
            ),
        ],
      ),
    );
  }
}
