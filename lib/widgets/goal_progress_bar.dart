import 'package:flutter/material.dart';

import '../services/lesson_goal_engine.dart';

class GoalProgressBar extends StatelessWidget {
  final GoalProgress progress;
  final String label;

  const GoalProgressBar({
    super.key,
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final pct = (progress.current / progress.target).clamp(0.0, 1.0);
    final completed = progress.completed;
    final color = completed ? Colors.green : accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${progress.current} / ${progress.target}',
                style: const TextStyle(color: Colors.white70)),
            if (completed)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.check_circle,
                    color: Colors.greenAccent, size: 16),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: pct),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            );
          },
        ),
      ],
    );
  }
}

class GoalCard extends StatelessWidget {
  final GoalProgress daily;
  final GoalProgress weekly;

  const GoalCard({
    super.key,
    required this.daily,
    required this.weekly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoalProgressBar(progress: daily, label: 'Daily Goal'),
          const SizedBox(height: 12),
          GoalProgressBar(progress: weekly, label: 'Weekly Goal'),
        ],
      ),
    );
  }
}
