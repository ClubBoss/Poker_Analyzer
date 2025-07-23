import 'package:shared_preferences/shared_preferences.dart';

class StreakTrackerService {
  StreakTrackerService._();
  static final StreakTrackerService instance = StreakTrackerService._();

  static const String _lastKey = 'lastActiveDate';
  static const String _currentKey = 'currentStreak';
  static const String _bestKey = 'bestStreak';
  static const String _daysKey = 'streakActiveDays';
  static const List<int> milestones = [3, 7, 14, 30, 60, 100];

  Future<bool> markActiveToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    var current = prefs.getInt(_currentKey) ?? 0;
    var best = prefs.getInt(_bestKey) ?? current;
    final list = prefs.getStringList(_daysKey) ?? <String>[];
    final todayStr = today.toIso8601String().split('T').first;
    final set = list.toSet();
    set.add(todayStr);

    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        current += 1;
      } else if (diff > 1) {
        current = 1;
      }
    } else {
      current = 1;
    }

    if (current > best) best = current;

    await prefs.setString(_lastKey, today.toIso8601String());
    await prefs.setInt(_currentKey, current);
    await prefs.setInt(_bestKey, best);
    await prefs.setStringList(_daysKey, set.toList());

    return milestones.contains(current);
  }

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    var current = prefs.getInt(_currentKey) ?? 0;
    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = DateTime.now().difference(lastDay).inDays;
      if (diff > 1) {
        current = 0;
        await prefs.setInt(_currentKey, 0);
      }
    } else if (current != 0) {
      current = 0;
      await prefs.setInt(_currentKey, 0);
    }
    return current;
  }

  Future<int> getBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestKey) ?? 0;
  }

  Future<Map<DateTime, bool>> getLast30DaysMap() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_daysKey) ?? <String>[];
    final set = list
        .map((e) => DateTime.tryParse(e))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 29));
    final map = <DateTime, bool>{};
    for (var i = 0; i < 30; i++) {
      final d = start.add(Duration(days: i));
      map[d] = set.contains(d);
    }
    return map;
  }
}
