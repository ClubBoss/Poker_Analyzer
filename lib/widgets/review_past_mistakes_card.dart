import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/template_storage_service.dart';
import '../models/v2/training_pack_template.dart';
import '../screens/v2/training_pack_play_screen.dart';

class ReviewPastMistakesCard extends StatelessWidget {
  const ReviewPastMistakesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final mistakes = context.watch<MistakeReviewPackService>().templateMistakes;
    final templates = context.watch<TemplateStorageService>().templates;
    final list = <MapEntry<TrainingPackTemplate, int>>[];
    mistakes.forEach((id, spots) {
      final tpl = templates.firstWhereOrNull((t) => t.id == id);
      if (tpl != null && spots.isNotEmpty) {
        list.add(MapEntry(tpl, spots.length));
      }
    });
    if (list.isEmpty) return const SizedBox.shrink();
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
          const Text(
            'Review Past Mistakes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final e in list)
                ElevatedButton(
                  onPressed: () async {
                    final tpl = await context
                        .read<MistakeReviewPackService>()
                        .review(context, e.key.id);
                    if (tpl != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrainingPackPlayScreen(
                            template: tpl,
                            original: tpl,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text('${e.key.name} (${e.value})'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
