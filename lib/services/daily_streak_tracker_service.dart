import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';


/// Tracks consecutive days with completed training sessions.
class DailyStreakTrackerService {
  DailyStreakTrackerService._();

  static final DailyStreakTrackerService instance =
      DailyStreakTrackerService._();

  static const _lastDateKey = 'daily_streak_last';
  static const _countKey = 'daily_streak_count';

  final _controller = StreamController<int>.broadcast();
  Stream<int> get streakStream => _controller.stream;

  /// Marks today as a completed training day and updates the streak.
  Future<void> markCompletedToday() async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_lastDateKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    int count = prefs.getInt(_countKey) ?? 0;

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

    await prefs.setString(_lastDateKey, today.toIso8601String());
    await prefs.setInt(_countKey, count);
    _controller.add(count);
  }

  /// Returns the current streak value. Resets to 0 if a day was missed.
  Future<int> getCurrentStreak() async {
    final prefs = await PreferencesService.getInstance();
    final lastStr = prefs.getString(_lastDateKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    int count = prefs.getInt(_countKey) ?? 0;

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

  /// Returns the date when the last training was recorded, if any.
  Future<DateTime?> getLastCompletionDate() async {
    final prefs = await PreferencesService.getInstance();
    final lastStr = prefs.getString(_lastDateKey);
    return lastStr != null ? DateTime.tryParse(lastStr) : null;
  }

  /// Clears the stored streak information. Useful for tests.
  Future<void> reset() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.remove(_lastDateKey);
    await prefs.remove(_countKey);
    _controller.add(0);
  }
}

