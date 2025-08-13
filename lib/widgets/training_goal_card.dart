import 'package:flutter/material.dart';

import '../models/training_goal.dart';
import '../models/goal_progress.dart';
import '../services/goal_completion_engine.dart';
import '../services/goal_engagement_tracker.dart';
import '../models/goal_engagement.dart';
import '../utils/goal_status_utils.dart';

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
    final prog = progress;
    final completed =
        prog != null && GoalCompletionEngine.instance.isGoalCompleted(prog);
    return Opacity(
      opacity: completed ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (prog != null) _GoalProgressBadge(progress: prog),
              ],
            ),
            if (goal.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                goal.description,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (prog != null) ...[
              const SizedBox(height: 4),
              Text(
                getGoalStatus(prog),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  final tag = goal.tag;
                  if (tag != null) {
                    await GoalEngagementTracker.instance.log(
                      GoalEngagement(
                        tag: tag,
                        action: 'start',
                        timestamp: DateTime.now(),
                      ),
                    );
                  }
                  onStart?.call();
                },
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text('Начать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressBadge extends StatelessWidget {
  final GoalProgress progress;
  const _GoalProgressBadge({required this.progress});

  @override
  Widget build(BuildContext context) {
    final completed = GoalCompletionEngine.instance.isGoalCompleted(progress);
    final color = completed ? Colors.green[700] : Colors.grey[700];
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        getGoalStatus(progress),
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
