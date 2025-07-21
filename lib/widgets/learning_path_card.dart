import 'package:flutter/material.dart';

import '../models/learning_path_template_v2.dart';
import '../theme/app_colors.dart';

class LearningPathCard extends StatelessWidget {
  final LearningPathTemplateV2 template;
  final VoidCallback? onTap;

  const LearningPathCard({
    super.key,
    required this.template,
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
          ],
        ),
      ),
    );
  }
}
