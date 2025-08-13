import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/daily_streak_tracker_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('increments when training on consecutive days', () async {
    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await prefs.setString('daily_streak_last', yesterday.toIso8601String());
    await prefs.setInt('daily_streak_count', 2);

    await DailyStreakTrackerService.instance.markCompletedToday();
    final count = prefs.getInt('daily_streak_count');
    expect(count, 3);
  });

  test('resets when day is skipped', () async {
    final prefs = await SharedPreferences.getInstance();
    final old = DateTime.now().subtract(const Duration(days: 3));
    await prefs.setString('daily_streak_last', old.toIso8601String());
    await prefs.setInt('daily_streak_count', 5);

    await DailyStreakTrackerService.instance.markCompletedToday();
    final count = prefs.getInt('daily_streak_count');
    expect(count, 1);
  });

  test('does not change when completed twice same day', () async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    await prefs.setString('daily_streak_last', today.toIso8601String());
    await prefs.setInt('daily_streak_count', 4);

    await DailyStreakTrackerService.instance.markCompletedToday();
    final count = prefs.getInt('daily_streak_count');
    expect(count, 4);
  });

  test('getCurrentStreak resets if gap is too big', () async {
    final prefs = await SharedPreferences.getInstance();
    final old = DateTime.now().subtract(const Duration(days: 2));
    await prefs.setString('daily_streak_last', old.toIso8601String());
    await prefs.setInt('daily_streak_count', 7);

    final current = await DailyStreakTrackerService.instance.getCurrentStreak();
    expect(current, 0);
    expect(prefs.getInt('daily_streak_count'), 0);
  });
}
