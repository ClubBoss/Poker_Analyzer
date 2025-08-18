import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'achievement_service.dart';

class DailyLearningGoalService extends ChangeNotifier {
  static const _prefKey = 'daily_learning_goal_completed_at';
  static const _streakKey = 'daily_learning_goal_streak';
  static const _daysKey = 'daily_learning_goal_days';
  static const _maxStreakKey = 'daily_learning_goal_max_streak';

  Timer? _timer;
  DateTime? _lastCompleted;
  int streakCount = 0;
  int maxStreak = 0;
  Set<String> _completedDays = {};

  DailyLearningGoalService();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefKey);
    _lastCompleted = str != null ? DateTime.tryParse(str) : null;
    streakCount = prefs.getInt(_streakKey) ?? 0;
    _completedDays = (prefs.getStringList(_daysKey) ?? []).toSet();
    maxStreak = prefs.getInt(_maxStreakKey) ?? streakCount;
    _schedule();
    notifyListeners();
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), () {
      notifyListeners();
      _schedule();
    });
  }

  Future<void> markCompleted() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final dayKey = now.toIso8601String().split('T').first;
    if (_lastCompleted != null) {
      if (_sameDay(_lastCompleted!, now)) {
        // Already completed today, nothing to update.
      } else if (_sameDay(
        _lastCompleted!,
        now.subtract(const Duration(days: 1)),
      )) {
        streakCount += 1;
      } else {
        streakCount = 1;
      }
    } else {
      streakCount = 1;
    }
    _completedDays.add(dayKey);
    await prefs.setStringList(_daysKey, _completedDays.toList());
    await prefs.setString(_prefKey, now.toIso8601String());
    await prefs.setInt(_streakKey, streakCount);
    if (streakCount > maxStreak) {
      maxStreak = streakCount;
      await prefs.setInt(_maxStreakKey, maxStreak);
    }
    _lastCompleted = now;
    AchievementService.instance.checkAll();
    notifyListeners();
  }

  bool get completedToday {
    final last = _lastCompleted;
    if (last == null) return false;
    return _sameDay(last, DateTime.now());
  }

  Future<bool> isGoalCompleted(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefKey);
    final last = str != null ? DateTime.tryParse(str) : null;
    if (last == null) return false;
    return _sameDay(last, date);
  }

  int getCurrentStreak() => streakCount;

  List<DateTime> getCompletedDays() {
    return [for (final s in _completedDays) DateTime.parse(s)];
  }

  int getMaxStreak() => maxStreak;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
