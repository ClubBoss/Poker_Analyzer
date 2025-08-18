import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/theory_lesson_completion_logger.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logCompletion adds unique entry per lesson per day', () async {
    final logger = TheoryLessonCompletionLogger();
    await logger.logCompletion('lessonA');
    await logger.logCompletion('lessonA');
    final entries = await logger.getCompletions();
    expect(entries.length, 1);
    expect(entries.first.lessonId, 'lessonA');
  });

  test('getCompletionsCountFor counts per day', () async {
    final logger = TheoryLessonCompletionLogger();
    await logger.logCompletion('lesson1');
    await logger.logCompletion('lesson2');
    final count = await logger.getCompletionsCountFor(DateTime.now());
    expect(count, 2);
  });

  test('getCompletions filters by since', () async {
    SharedPreferences.setMockInitialValues({
      'lesson_completion_log': jsonEncode([
        {
          'lessonId': 'old',
          'timestamp': DateTime.utc(2021, 1, 1).toIso8601String(),
        },
        {
          'lessonId': 'new',
          'timestamp': DateTime.utc(2021, 1, 2).toIso8601String(),
        },
      ]),
    });
    final logger = TheoryLessonCompletionLogger();
    final entries = await logger.getCompletions(
      since: DateTime.utc(2021, 1, 2),
    );
    expect(entries.length, 1);
    expect(entries.first.lessonId, 'new');
  });

  test(
    'logging same lesson on different days creates separate entries',
    () async {
      final yesterday = DateTime.now().toUtc().subtract(
        const Duration(days: 1),
      );
      SharedPreferences.setMockInitialValues({
        'lesson_completion_log': jsonEncode([
          {'lessonId': 'lessonX', 'timestamp': yesterday.toIso8601String()},
        ]),
      });
      final logger = TheoryLessonCompletionLogger();
      await logger.logCompletion('lessonX');
      final entries = await logger.getCompletions();
      expect(entries.length, 2);
    },
  );
}
