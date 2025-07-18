import 'package:flutter/material.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import '../models/training_type.dart';

class PackCard extends StatelessWidget {
  final TrainingPackTemplateV2 template;
  final VoidCallback onTap;
  const PackCard({super.key, required this.template, required this.onTap});

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
            Text(template.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(template.trainingType.name,
                  style: const TextStyle(color: Colors.white70)),
            ),
            if (template.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(template.tags.join(', '),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
