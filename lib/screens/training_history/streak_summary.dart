import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StreakSummary extends StatelessWidget {
  final bool show;
  final int current;
  final int best;
  const StreakSummary({
    super.key,
    required this.show,
    required this.current,
    required this.best,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              'Текущий стрик: $current дней',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Лучший стрик: $best дней',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
