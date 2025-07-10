import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2/training_pack_template.dart';
import '../services/training_session_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/adaptive_training_service.dart';
import 'training_session_screen.dart';

class TrainingTemplateDetailScreen extends StatelessWidget {
  final TrainingPackTemplate template;
  final TrainingPackStat? stat;
  const TrainingTemplateDetailScreen({super.key, required this.template, this.stat});

  @override
  Widget build(BuildContext context) {
    final accuracy = (stat?.accuracy ?? 0) * 100;
    final ev = stat?.postEvPct ?? 0;
    final icm = stat?.postIcmPct ?? 0;
    final dEv = ev - (stat?.preEvPct ?? 0);
    final dIcm = icm - (stat?.preIcmPct ?? 0);
    final rating = ((stat?.accuracy ?? 0) * 5).clamp(1, 5).round();
    final focus = template.handTypeSummary();
    final diff = template.difficultyLevel;
    final hasMistakes = context.read<MistakeReviewPackService>().hasMistakes(template.id);
    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (template.description.isNotEmpty)
              Text(template.description, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Row(children:[for(var i=0;i<rating;i++)const Icon(Icons.star,color:Colors.amber)],),
            if (accuracy > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Accuracy ${accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70)),
              ),
            const SizedBox(height: 8),
            Text('Difficulty: $diff', style: const TextStyle(color: Colors.white)),
            Text('EV ${ev.toStringAsFixed(1)}%  ICM ${icm.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white)),
            if (stat != null)
              Text(
                'ΔEV ${dEv >= 0 ? '+' : ''}${dEv.toStringAsFixed(1)}%  ΔICM ${dIcm >= 0 ? '+' : ''}${dIcm.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white70),
              ),
            if (focus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(focus, style: const TextStyle(color: Colors.white70)),
              ),
            if (hasMistakes)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Есть ошибки', style: TextStyle(color: Colors.orange)),
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.read<TrainingSessionService>().startSession(template);
                      if (context.mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
                        );
                      }
                    },
                    child: const Text('Начать'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasMistakes
                        ? () async {
                            final review = await context.read<MistakeReviewPackService>().review(context, template.id);
                            if (review != null && context.mounted) {
                              await context.read<TrainingSessionService>().startSession(review);
                              if (context.mounted) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
                                );
                              }
                            }
                          }
                        : null,
                    child: const Text('Ошибки'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
