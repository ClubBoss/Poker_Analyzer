import 'package:flutter/material.dart';

import '../../models/training_result.dart';
import '../../theme/app_colors.dart';
import 'streak_summary.dart';

class StatsSummary extends StatelessWidget {
  final List<TrainingResult> sessions;
  final bool showStreak;
  final int currentStreak;
  final int bestStreak;

  const StatsSummary({
    super.key,
    required this.sessions,
    required this.showStreak,
    required this.currentStreak,
    required this.bestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final totalSessions = sessions.length;
    final totalCorrect = sessions.fold<int>(0, (sum, r) => sum + r.correct);
    final avg = sessions.isEmpty
        ? 0.0
        : sessions.map((r) => r.accuracy).reduce((a, b) => a + b) /
            sessions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Сессии: $totalSessions',
                    style: const TextStyle(color: Colors.white)),
                Text('Верно: $totalCorrect',
                    style: const TextStyle(color: Colors.white)),
                Text('Средняя: ${avg.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        StreakSummary(
          show: showStreak,
          current: currentStreak,
          best: bestStreak,
        ),
      ],
    );
  }
}
