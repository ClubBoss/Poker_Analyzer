import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'lesson_goal_streak_engine.dart';
import '../utils/singleton_mixin.dart';

class GoalProgress {
  final int current;
  final int target;
  final bool completed;

  const GoalProgress({
    required this.current,
    required this.target,
    required this.completed,
  });
}

class LessonGoalEngine with SingletonMixin<LessonGoalEngine> {
  LessonGoalEngine._();

  static LessonGoalEngine get instance =>
      SingletonMixin.instance<LessonGoalEngine>(() => LessonGoalEngine._());

  static const int _dailyTarget = 5;
  static const int _weeklyTarget = 25;

  static const String _dailyDateKey = 'goal_daily_date';
  static const String _dailyCountKey = 'goal_daily_count';
  static const String _weeklyStartKey = 'goal_weekly_start';
  static const String _weeklyCountKey = 'goal_weekly_count';

  Future<GoalProgress> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetDailyIfNeeded(prefs);
    final count = prefs.getInt(_dailyCountKey) ?? 0;
    final progress = GoalProgress(
      current: count,
      target: _dailyTarget,
      completed: count >= _dailyTarget,
    );
    if (progress.completed) {
      unawaited(LessonGoalStreakEngine.instance.updateStreakOnGoalCompletion());
    }
    return progress;
  }

  Future<GoalProgress> getWeeklyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetWeeklyIfNeeded(prefs);
    final count = prefs.getInt(_weeklyCountKey) ?? 0;
    return GoalProgress(
      current: count,
      target: _weeklyTarget,
      completed: count >= _weeklyTarget,
    );
  }

  Future<void> updateProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetDailyIfNeeded(prefs);
    await _resetWeeklyIfNeeded(prefs);
    final prevDaily = prefs.getInt(_dailyCountKey) ?? 0;
    final newDaily = prevDaily + 1;
    await prefs.setInt(_dailyCountKey, newDaily);
    await prefs.setInt(
        _weeklyCountKey, (prefs.getInt(_weeklyCountKey) ?? 0) + 1);
    if (prevDaily < _dailyTarget && newDaily >= _dailyTarget) {
      unawaited(LessonGoalStreakEngine.instance.updateStreakOnGoalCompletion());
    }
  }

  Future<void> _resetDailyIfNeeded(SharedPreferences prefs) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = prefs.getString(_dailyDateKey);
    final stored = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (stored == null ||
        DateTime(stored.year, stored.month, stored.day) != today) {
      await prefs.setString(
          _dailyDateKey, today.toIso8601String().split('T').first);
      await prefs.setInt(_dailyCountKey, 0);
    }
  }

  Future<void> _resetWeeklyIfNeeded(SharedPreferences prefs) async {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final startStr = prefs.getString(_weeklyStartKey);
    final stored = startStr != null ? DateTime.tryParse(startStr) : null;
    if (stored == null ||
        DateTime(stored.year, stored.month, stored.day) != startOfWeek) {
      await prefs.setString(
          _weeklyStartKey, startOfWeek.toIso8601String().split('T').first);
      await prefs.setInt(_weeklyCountKey, 0);
    }
  }
}
