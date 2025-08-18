import 'package:shared_preferences/shared_preferences.dart';

import 'recall_tag_decay_summary_service.dart';

/// Tracks consecutive days with no critical decay across all tags.
class DecayStreakTrackerService {
  final RecallTagDecaySummaryService summary;

  const DecayStreakTrackerService({RecallTagDecaySummaryService? summary})
    : summary = summary ?? const RecallTagDecaySummaryService();

  static const String _countKey = 'decay_streak_count';
  static const String _lastCheckKey = 'decay_streak_last_check';

  /// Returns current streak of days without critical decay.
  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey) ?? 0;
  }

  /// Evaluates today's decay summary and updates streak accordingly.
  Future<void> evaluateToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_lastCheckKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null &&
        today.difference(DateTime(last.year, last.month, last.day)).inDays ==
            0) {
      return;
    }

    final summaryResult = await summary.getSummary();
    var streak = prefs.getInt(_countKey) ?? 0;
    if (summaryResult.countCritical == 0) {
      if (last != null &&
          today.difference(DateTime(last.year, last.month, last.day)).inDays ==
              1) {
        streak += 1;
      } else {
        streak = 1;
      }
    } else {
      streak = 0;
    }

    await prefs.setInt(_countKey, streak);
    await prefs.setString(_lastCheckKey, today.toIso8601String());
  }
}
