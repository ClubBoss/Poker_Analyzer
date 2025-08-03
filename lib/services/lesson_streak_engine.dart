import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';


class LessonStreakEngine {
  LessonStreakEngine._();
  static final LessonStreakEngine instance = LessonStreakEngine._();

  static const _lastDayKey = 'lesson_streak_last_day';
  static const _countKey = 'lesson_streak_count';

  final _controller = StreamController<int>.broadcast();
  Stream<int> get streakStream => _controller.stream;

  Future<void> markTodayCompleted() async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_lastDayKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    var count = prefs.getInt(_countKey) ?? 0;

    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) return;
      if (diff == 1) {
        count += 1;
      } else {
        count = 1;
      }
    } else {
      count = 1;
    }

    await prefs.setString(
        _lastDayKey, today.toIso8601String().split('T').first);
    await prefs.setInt(_countKey, count);
    _controller.add(count);
  }

  Future<int> getCurrentStreak() async {
    final prefs = await PreferencesService.getInstance();
    final lastStr = prefs.getString(_lastDayKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    var count = prefs.getInt(_countKey) ?? 0;

    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = DateTime.now().difference(lastDay).inDays;
      if (diff > 1) {
        count = 0;
        await prefs.setInt(_countKey, 0);
      }
    } else if (count != 0) {
      count = 0;
      await prefs.setInt(_countKey, 0);
    }

    return count;
  }

  Future<DateTime?> getLastCompletionDate() async {
    final prefs = await PreferencesService.getInstance();
    final lastStr = prefs.getString(_lastDayKey);
    return lastStr != null ? DateTime.tryParse(lastStr) : null;
  }

  Future<void> resetStreak() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.remove(_lastDayKey);
    await prefs.remove(_countKey);
    _controller.add(0);
  }
}
