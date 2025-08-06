import 'package:flutter/material.dart';

import '../widgets/lesson_streak_celebration_overlay.dart';
import 'lesson_streak_tracker_service.dart';

/// Triggers a celebration overlay when the user sets a new lesson streak record.
class LessonStreakCelebrationService {
  final LessonStreakTrackerService tracker;
  bool _shown = false;

  LessonStreakCelebrationService({LessonStreakTrackerService? tracker})
      : tracker = tracker ?? LessonStreakTrackerService.instance;

  /// Checks for a new streak record and shows [LessonStreakCelebrationOverlay]
  /// once per app session.
  Future<void> maybeCelebrate(BuildContext context) async {
    if (_shown) return;

    final previousBest = await tracker.getLongestStreak();
    tracker.resetCache();
    final current = await tracker.getCurrentStreak();
    if (current <= previousBest) return;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _shown = true;
    late OverlayEntry entry;
    void close() => entry.remove();
    entry = OverlayEntry(
      builder: (_) => LessonStreakCelebrationOverlay(
        streak: current,
        onDismiss: close,
      ),
    );
    overlay.insert(entry);
  }
}
