import 'package:flutter/material.dart';

import '../models/learning_path_template_v2.dart';
import '../theme/app_colors.dart';

import '../models/learning_path_progress.dart';

class LearningPathCard extends StatelessWidget {
  final LearningPathTemplateV2 template;
  final LearningPathProgress? progress;
  final VoidCallback? onTap;

  const LearningPathCard({
    super.key,
    required this.template,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: progress != null && progress!.finished
              ? Border.all(color: Colors.greenAccent)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (template.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  template.description,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            if (template.recommendedFor != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  template.recommendedFor!,
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            if (progress != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress!.percentComplete.clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.greenAccent,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            progress!.finished
                                ? 'Завершено'
                                : '${progress!.completedStages} из ${progress!.totalStages} этапов',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '${(progress!.percentComplete * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        if (progress!.finished)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
