import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/lesson_streak_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LessonStreakTrackerService.instance.resetCache();
  });

  test('computes current and longest lesson streaks', () async {
    final now = DateTime.now().toUtc();
    SharedPreferences.setMockInitialValues({
      'lesson_completion_log': jsonEncode([
        {
          'lessonId': 'a',
          'timestamp': now.subtract(const Duration(days: 10)).toIso8601String(),
        },
        {
          'lessonId': 'b',
          'timestamp': now.subtract(const Duration(days: 9)).toIso8601String(),
        },
        {
          'lessonId': 'c',
          'timestamp': now.subtract(const Duration(days: 8)).toIso8601String(),
        },
        {
          'lessonId': 'd',
          'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'lessonId': 'e',
          'timestamp': now.toIso8601String(),
        }
      ])
    });

    final current = await LessonStreakTrackerService.instance.getCurrentStreak();
    final longest = await LessonStreakTrackerService.instance.getLongestStreak();
    expect(current, 2);
    expect(longest, 3);
  });

  test('streak resets if gap exceeds one day', () async {
    final now = DateTime.now().toUtc();
    SharedPreferences.setMockInitialValues({
      'lesson_completion_log': jsonEncode([
        {
          'lessonId': 'x',
          'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
        }
      ])
    });

    final current = await LessonStreakTrackerService.instance.getCurrentStreak();
    final longest = await LessonStreakTrackerService.instance.getLongestStreak();
    expect(current, 0);
    expect(longest, 1);
  });
}
