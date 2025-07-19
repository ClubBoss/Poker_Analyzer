import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/daily_learning_goal_service.dart';

class DailyLearningGoalBanner extends StatelessWidget {
  const DailyLearningGoalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyLearningGoalService>();
    final completed = service.completedToday;
    final color = completed ? Colors.green.shade700 : Colors.grey[850];
    final text = completed
        ? '✅ Цель выполнена!'
        : '🎯 Цель дня: завершить 1 пак. Ты сможешь!';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
