import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/mini_lesson_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('schedule orders by view count and recency', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mini_lesson_progress_a',
      jsonEncode({
        'viewCount': 2,
        'lastViewed': '2024-01-02T00:00:00.000',
        'completed': false,
      }),
    );
    await prefs.setString(
      'mini_lesson_progress_b',
      jsonEncode({
        'viewCount': 1,
        'lastViewed': '2024-01-02T00:00:00.000',
        'completed': false,
      }),
    );
    await prefs.setString(
      'mini_lesson_progress_c',
      jsonEncode({
        'viewCount': 1,
        'lastViewed': '2024-01-01T00:00:00.000',
        'completed': false,
      }),
    );

    final scheduler = MiniLessonScheduler();
    final res = await scheduler.schedule(['a', 'b', 'c']);
    expect(res, ['c', 'b']);
  });

  test('schedule skips completed and excluded ids', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mini_lesson_progress_a',
      jsonEncode({'viewCount': 0, 'completed': true}),
    );
    await prefs.setString(
      'mini_lesson_progress_c',
      jsonEncode({'viewCount': 0}),
    );

    final scheduler = MiniLessonScheduler();
    final res = await scheduler.schedule(['a', 'b', 'c'], excludeIds: ['b']);
    expect(res, ['c']);
  });
}
