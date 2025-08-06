import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/widgets/lesson_streak_badge_tooltip_widget.dart';
import 'package:poker_analyzer/services/lesson_streak_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LessonStreakTrackerService.instance.resetCache();
  });

  testWidgets('shows longest streak in tooltip', (tester) async {
    final now = DateTime.now().toUtc();
    SharedPreferences.setMockInitialValues({
      'lesson_completion_log': jsonEncode([
        {
          'lessonId': 'a',
          'timestamp':
              now.subtract(const Duration(days: 10)).toIso8601String(),
        },
        {
          'lessonId': 'b',
          'timestamp':
              now.subtract(const Duration(days: 9)).toIso8601String(),
        },
        {
          'lessonId': 'c',
          'timestamp':
              now.subtract(const Duration(days: 8)).toIso8601String(),
        },
        {
          'lessonId': 'd',
          'timestamp':
              now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'lessonId': 'e',
          'timestamp': now.toIso8601String(),
        }
      ])
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LessonStreakBadgeTooltipWidget(),
        ),
      ),
    );
    await tester.pump();

    await tester.longPress(find.byType(LessonStreakBadgeTooltipWidget));
    await tester.pumpAndSettle();

    expect(find.text('Your longest streak: 3 days'), findsOneWidget);
  });
}

