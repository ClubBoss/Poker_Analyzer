import 'package:shared_preferences/shared_preferences.dart';

import 'goal_progress_persistence_service.dart';

class GoalStreakInfo {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastCompletedDay;

  const GoalStreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDay,
  });
}

class GoalStreakTrackerService {
  GoalStreakTrackerService._();
  static final GoalStreakTrackerService instance = GoalStreakTrackerService._();

  static const _currentKey = 'goal_streak_current';
  static const _longestKey = 'goal_streak_longest';
  static const _lastKey = 'goal_streak_last_day';

  Future<void> resetForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentKey);
    await prefs.remove(_longestKey);
    await prefs.remove(_lastKey);
  }

  Future<GoalStreakInfo> getStreakInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_lastKey);
    var current = prefs.getInt(_currentKey) ?? 0;
    var longest = prefs.getInt(_longestKey) ?? current;
    DateTime? lastDay =
        lastStr != null ? DateTime.tryParse(lastStr) : null;

    final logs = await GoalProgressPersistenceService.instance.getAllLogs();
    if (logs.isNotEmpty) {
      final days = <DateTime>[];
      for (final l in logs..sort((a, b) => a.completedAt.compareTo(b.completedAt))) {
        final d = DateTime(l.completedAt.year, l.completedAt.month, l.completedAt.day);
        if (days.isEmpty || days.last != d) {
          days.add(d);
        }
      }

      int best = 1;
      int count = 1;
      for (var i = 1; i < days.length; i++) {
        final diff = days[i].difference(days[i - 1]).inDays;
        if (diff == 1) {
          count += 1;
        } else if (diff > 1) {
          if (count > best) best = count;
          count = 1;
        }
      }
      if (count > best) best = count;
      longest = best;
      lastDay = days.last;
      current = count;
      final today = DateTime.now();
      final diff = DateTime(today.year, today.month, today.day)
          .difference(lastDay)
          .inDays;
      if (diff > 1) current = 0;
    } else {
      current = 0;
      lastDay = null;
    }

    await prefs.setInt(_currentKey, current);
    await prefs.setInt(_longestKey, longest);
    if (lastDay != null) {
      await prefs.setString(_lastKey, lastDay.toIso8601String());
    } else {
      await prefs.remove(_lastKey);
    }

    return GoalStreakInfo(
      currentStreak: current,
      longestStreak: longest,
      lastCompletedDay: lastDay ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
