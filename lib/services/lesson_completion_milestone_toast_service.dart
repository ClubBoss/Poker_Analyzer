import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows a short toast when daily lesson completion milestones are reached.
class LessonCompletionMilestoneToastService {
  LessonCompletionMilestoneToastService._();
  static final LessonCompletionMilestoneToastService instance =
      LessonCompletionMilestoneToastService._();

  static const _prefsKeyPrefix = 'lesson_completion_milestone_';
  static const Map<int, String> _messages = {
    1: 'Nice start!',
    3: 'Keep going!',
    5: '🔥 Crushing it!',
  };

  Future<void> showIfMilestoneReached(
    BuildContext context,
    int completionCount,
  ) async {
    final message = _messages[completionCount];
    if (message == null) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = '$_prefsKeyPrefix$completionCount';
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastShown = prefs.getString(key);
    if (lastShown == todayStr) return;

    await prefs.setString(key, todayStr);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
