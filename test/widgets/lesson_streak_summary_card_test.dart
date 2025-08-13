import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/widgets/lesson_streak_summary_card.dart';

void main() {
  testWidgets('shows when hitting new milestone', (tester) async {
    SharedPreferences.setMockInitialValues({
      'lesson_streak_count': 3,
      'lesson_streak_last_day':
          DateTime.now().toIso8601String().split('T').first,
    });
    await tester.pumpWidget(const MaterialApp(home: LessonStreakSummaryCard()));
    await tester.pumpAndSettle();
    expect(find.textContaining('3-day learning streak'), findsOneWidget);
  });

  testWidgets('does not show when milestone already shown', (tester) async {
    SharedPreferences.setMockInitialValues({
      'lesson_streak_count': 3,
      'lesson_streak_last_day':
          DateTime.now().toIso8601String().split('T').first,
      'lesson_streak_summary_shown': ['3'],
    });
    await tester.pumpWidget(const MaterialApp(home: LessonStreakSummaryCard()));
    await tester.pumpAndSettle();
    expect(find.textContaining('3-day learning streak'), findsNothing);
  });
}
