import 'package:flutter/material.dart';

import '../services/lesson_streak_tracker_service.dart';

/// Displays the current lesson streak as a small badge.
class LessonStreakBadgeWidget extends StatelessWidget {
  final bool dense;

  const LessonStreakBadgeWidget({super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: LessonStreakTrackerService.instance.getCurrentStreak(),
      builder: (context, snapshot) {
        final streak = snapshot.data ?? 0;
        if (streak <= 0) return const SizedBox.shrink();
        final iconSize = dense ? 16.0 : 20.0;
        final fontSize = dense ? 12.0 : 14.0;
        final spacing = dense ? 4.0 : 6.0;
        final label = dense ? '$streak' : '$streak-day streak';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: iconSize,
              color: Colors.deepOrange,
            ),
            SizedBox(width: spacing),
            Text(
              label,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }
}
