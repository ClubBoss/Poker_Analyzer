import 'package:shared_preferences/shared_preferences.dart';

class LessonGoalStreakEngine {
  LessonGoalStreakEngine._();
  static final LessonGoalStreakEngine instance = LessonGoalStreakEngine._();

  static const String _countKey = 'goal_streak_count';
  static const String _bestKey = 'goal_streak_best';
  static const String _lastKey = 'goal_streak_last_date';

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_countKey) ?? 0;
    final lastStr = prefs.getString(_lastKey);
    if (lastStr == null) return 0;
    final last = DateTime.tryParse(lastStr);
    if (last == null) return 0;
    final today = DateTime.now();
    final lastDay = DateTime(last.year, last.month, last.day);
    final diff = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(lastDay).inDays;
    if (diff > 1) {
      await prefs.setInt(_countKey, 0);
      return 0;
    }
    return count;
  }

  Future<int> getBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestKey) ?? 0;
  }

  Future<void> updateStreakOnGoalCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    var count = prefs.getInt(_countKey) ?? 0;
    var best = prefs.getInt(_bestKey) ?? count;

    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        return;
      } else if (diff == 1) {
        count += 1;
      } else {
        count = 1;
      }
    } else {
      count = 1;
    }

    if (count > best) best = count;

    await prefs.setString(_lastKey, today.toIso8601String().split('T').first);
    await prefs.setInt(_countKey, count);
    await prefs.setInt(_bestKey, best);
  }
}
