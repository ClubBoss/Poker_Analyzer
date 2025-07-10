import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/adaptive_training_service.dart';
import '../services/training_session_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../models/v2/training_pack_template.dart';
import 'training_session_screen.dart';

class TrainingRecommendationScreen extends StatelessWidget {
  const TrainingRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AdaptiveTrainingService>();
    final list = service.recommended;
    return Scaffold(
      appBar: AppBar(title: const Text('Рекомендации')),
      body: list.isEmpty
          ? const Center(child: Text('Нет рекомендаций'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final tpl = list[index];
                final stat = service.statFor(tpl.id);
                final acc = (stat?.accuracy ?? 0) * 100;
                final ev = stat?.postEvPct ?? 0;
                final icm = stat?.postIcmPct ?? 0;
                final hasMistakes = context
                    .read<MistakeReviewPackService>()
                    .hasMistakes(tpl.id);
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(tpl.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${acc.toStringAsFixed(1)}% • EV ${ev.toStringAsFixed(1)}% • ICM ${icm.toStringAsFixed(1)}%' +
                          (hasMistakes ? ' • ошибки' : ''),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing:
                        const Icon(Icons.play_arrow, color: Colors.greenAccent),
                    onTap: () async {
                      await context
                          .read<TrainingSessionService>()
                          .startSession(tpl);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TrainingSessionScreen()),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
