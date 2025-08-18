import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/goals_service.dart';
import '../../services/saved_hand_manager_service.dart';
import '../../services/evaluation_executor_service.dart';
import '../../utils/responsive.dart';

class MainMenuProgressCard extends StatelessWidget {
  const MainMenuProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final goals = context.watch<GoalsService>();
    final executor = EvaluationExecutorService();
    final total = executor.summarizeHands(hands).totalHands;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = [
      for (final h in hands)
        if (h.date.isAfter(cutoff)) h,
    ];
    final recentSummary = executor.summarizeHands(recent);
    final accuracy = recentSummary.totalHands > 0
        ? recentSummary.accuracy
        : null;
    final completed = goals.goals.where((g) => g.completed).length;
    final streak = goals.errorFreeStreak;
    final show = total > 0 || accuracy != null || completed > 0 || streak > 0;
    if (!show) return const SizedBox.shrink();

    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
    return Container(
      margin: EdgeInsets.only(bottom: responsiveSize(context, 24)),
      padding: responsiveAll(context, 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.white),
              SizedBox(width: 8),
              Text(
                '📈 Мой прогресс',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (total > 0) line(Icons.stacked_bar_chart, '$total раздач'),
          if (accuracy != null)
            line(Icons.check, 'Точность: ${accuracy.toStringAsFixed(0)}%'),
          if (completed > 0) line(Icons.flag, 'Целей достигнуто: $completed'),
          if (streak > 0) line(Icons.flash_on, 'Стрик: $streak рук'),
        ],
      ),
    );
  }
}
