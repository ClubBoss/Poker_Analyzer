import 'package:flutter/material.dart';

import '../services/lesson_streak_tracker_service.dart';
import 'lesson_streak_badge_widget.dart';

/// Displays the current lesson streak badge with a tooltip revealing
/// the user's longest recorded streak when hovered or long-pressed.
class LessonStreakBadgeTooltipWidget extends StatelessWidget {
  final bool dense;

  const LessonStreakBadgeTooltipWidget({super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: LessonStreakTrackerService.instance.getLongestStreak(),
      builder: (context, snapshot) {
        final longest = snapshot.data ?? 0;
        final message = 'Your longest streak: $longest days';
        return Tooltip(
          message: message,
          child: LessonStreakBadgeWidget(dense: dense),
        );
      },
    );
  }
}
