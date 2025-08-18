import 'package:flutter/material.dart';

import '../services/lesson_goal_engine.dart';
import '../services/streak_tracker_service.dart';
import 'goal_progress_bar.dart';

/// Compact dashboard widget showing today's and weekly goal progress
/// together with current and best streak information.
class GoalDashboardWidget extends StatelessWidget {
  /// When true, uses preset mock values for easier UI testing.
  final bool mock;

  const GoalDashboardWidget({super.key, this.mock = false});

  Future<Map<String, dynamic>> _load() async {
    if (mock) {
      return {
        'daily': const GoalProgress(current: 3, target: 5, completed: false),
        'weekly': const GoalProgress(current: 12, target: 25, completed: false),
        'current': 3,
        'best': 6,
      };
    }
    final daily = await LessonGoalEngine.instance.getDailyGoal();
    final weekly = await LessonGoalEngine.instance.getWeeklyGoal();
    final current = await StreakTrackerService.instance.getCurrentStreak();
    final best = await StreakTrackerService.instance.getBestStreak();
    return {'daily': daily, 'weekly': weekly, 'current': current, 'best': best};
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<Map<String, dynamic>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final daily = data['daily'] as GoalProgress;
        final weekly = data['weekly'] as GoalProgress;
        final current = data['current'] as int;
        final best = data['best'] as int;
        final flames = current.clamp(0, 7);
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
              GoalProgressBar(progress: daily, label: '🎯 Today'),
              const SizedBox(height: 12),
              GoalProgressBar(progress: weekly, label: '📆 Week'),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < flames; i++)
                    Text('🔥', style: TextStyle(fontSize: 20, color: accent)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '🔥 \u0421\u0442\u0440\u0438\u043A: $current \u0434\u043D\u044F \u043F\u043E\u0434\u0440\u044F\u0434',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '🏆 Best: $best',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}
