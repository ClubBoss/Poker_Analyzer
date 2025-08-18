import 'package:flutter/material.dart';

import '../services/decay_streak_tracker_service.dart';

/// Progress bar visualizing current decay streak toward next milestone.
class DecayStreakProgressBarWidget extends StatelessWidget {
  /// Service providing current decay streak.
  final DecayStreakTrackerService tracker;

  const DecayStreakProgressBarWidget({
    super.key,
    this.tracker = const DecayStreakTrackerService(),
  });

  Future<int> _loadStreak() {
    return tracker.getCurrentStreak();
  }

  int _nextMilestone(int current) {
    const milestones = [3, 7, 14, 30];
    for (final m in milestones) {
      if (current < m) return m;
    }
    return milestones.last;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<int>(
      future: _loadStreak(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final current = snapshot.data ?? 0;
        final milestone = _nextMilestone(current);
        final pct = (current / milestone).clamp(0.0, 1.0);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '🧠 No critical decay:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$current-day streak',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '$current / $milestone',
                    style: const TextStyle(color: Colors.white70),
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
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 6,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
