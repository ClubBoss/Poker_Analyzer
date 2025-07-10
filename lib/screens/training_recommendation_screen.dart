import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/adaptive_training_service.dart';
import '../services/training_session_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../models/v2/training_pack_template.dart';
import 'training_session_screen.dart';
import 'training_template_detail_screen.dart';

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
                final rating = ((stat?.accuracy ?? 0) * 5).clamp(1, 5).round();
                final focus = tpl.handTypeSummary();
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
                          (hasMistakes ? ' • ошибки' : '') +
                          (focus.isNotEmpty ? ' • $focus' : ''),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            for (var i = 0; i < rating; i++)
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16)
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right,
                            color: Colors.greenAccent),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrainingTemplateDetailScreen(
                            template: tpl,
                            stat: stat,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
