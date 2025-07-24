import 'package:flutter/material.dart';

import '../models/training_goal.dart';
import '../models/goal_progress.dart';

class TrainingGoalCard extends StatelessWidget {
  final TrainingGoal goal;
  final VoidCallback? onStart;
  final GoalProgress? progress;
  const TrainingGoalCard({
    super.key,
    required this.goal,
    this.onStart,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (goal.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              goal.description,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 4),
            Text(
              'Пройдено: ${progress!.stagesCompleted} стадий · Средняя точность: '
              '${progress!.averageAccuracy.toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Начать'),
            ),
          ),
        ],
      ),
    );
  }
}
