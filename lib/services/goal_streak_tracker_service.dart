import 'package:shared_preferences/shared_preferences.dart';

import 'goal_progress_persistence_service.dart';

class GoalStreakInfo {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastCompletedDay;

  GoalStreakInfo({
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
    DateTime? lastDay = lastStr != null ? DateTime.tryParse(lastStr) : null;

    final days = await _loadLogs();
    if (days.isNotEmpty) {
      final result = _calculateStreak(days);
      current = result.current;
      longest = result.longest;
      lastDay = result.lastDay;
    } else {
      current = 0;
      lastDay = null;
    }

    await _persistStreak(prefs, current, longest, lastDay);

    return GoalStreakInfo(
      currentStreak: current,
      longestStreak: longest,
      lastCompletedDay: lastDay ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Future<List<DateTime>> _loadLogs() async {
    final logs = await GoalProgressPersistenceService.instance.getAllLogs();
    final days = <DateTime>[];
    for (final l in logs) {
      final d = DateTime(
        l.completedAt.year,
        l.completedAt.month,
        l.completedAt.day,
      );
      if (days.isEmpty || days.last != d) {
        days.add(d);
      }
    }
    return days;
  }

  ({int current, int longest, DateTime? lastDay}) _calculateStreak(
    List<DateTime> days,
  ) {
    if (days.isEmpty) {
      return (current: 0, longest: 0, lastDay: null);
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

    final lastDay = days.last;
    final today = DateTime.now();
    final diff = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(lastDay).inDays;
    final current = diff > 1 ? 0 : count;
    return (current: current, longest: best, lastDay: lastDay);
  }

  Future<void> _persistStreak(
    SharedPreferences prefs,
    int current,
    int longest,
    DateTime? lastDay,
  ) async {
    await prefs.setInt(_currentKey, current);
    await prefs.setInt(_longestKey, longest);
    if (lastDay != null) {
      await prefs.setString(_lastKey, lastDay.toIso8601String());
    } else {
      await prefs.remove(_lastKey);
    }
  }
}
