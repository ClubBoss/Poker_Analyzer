import 'package:flutter/material.dart';
import '../services/goal_progress_persistence_service.dart';

/// Progress bar widget showing weekly XP progress towards [weeklyTarget].
class SmartGoalProgressBar extends StatelessWidget {
  /// Weekly XP target to reach.
  final int weeklyTarget;

  const SmartGoalProgressBar({super.key, this.weeklyTarget = 200});

  Future<int> _loadXP() {
    return GoalProgressPersistenceService.instance.getWeeklyXP();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<int>(
      future: _loadXP(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final xp = snapshot.data ?? 0;
        final pct = (xp / weeklyTarget).clamp(0.0, 1.0);
        final completed = xp >= weeklyTarget;
        final color = completed ? Colors.green : accent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$xp/$weeklyTarget XP this week',
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                if (completed)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: pct),
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
      },
    );
  }
}
