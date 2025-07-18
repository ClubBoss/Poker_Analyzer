import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AverageAccuracySummary extends StatelessWidget {
  final double accuracy;
  const AverageAccuracySummary({super.key, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Средняя точность: ${accuracy.toStringAsFixed(1)}%',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
