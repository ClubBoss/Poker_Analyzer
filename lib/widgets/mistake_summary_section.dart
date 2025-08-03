import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/summary_result.dart';

class MistakeSummarySection extends StatelessWidget {
  final SummaryResult summary;
  const MistakeSummarySection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final mistakes = summary.incorrect;
    final total = summary.totalHands;
    final accuracy = summary.accuracy;
    final mistakePercent = total > 0 ? mistakes / total * 100 : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ошибки: $mistakes', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Средняя точность: ${accuracy.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Доля рук с ошибками: ${mistakePercent.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
