import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_auto_injection_logger_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TheoryAutoInjectionLoggerService.instance.resetForTest();
  });

  test('logAutoInjection saves entry', () async {
    final now = DateTime.now();
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's1',
      lessonId: 'l1',
      timestamp: now,
    );
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('auto_theory_injection_log');
    expect(raw, isNotNull);
    final list = jsonDecode(raw!) as List;
    expect(list.length, 1);
    final data = list.first as Map<String, dynamic>;
    expect(data['spotId'], 's1');
    expect(data['lessonId'], 'l1');
    expect(data['timestamp'], now.toIso8601String());
  });

  test('getRecentLogs returns most recent first', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'auto_theory_injection_log': jsonEncode([
        {
          'spotId': 'a',
          'lessonId': 'l1',
          'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'spotId': 'b',
          'lessonId': 'l2',
          'timestamp': now.toIso8601String(),
        },
      ]),
    });
    TheoryAutoInjectionLoggerService.instance.resetForTest();
    final logs = await TheoryAutoInjectionLoggerService.instance.getRecentLogs(
      limit: 1,
    );
    expect(logs.length, 1);
    expect(logs.first.spotId, 'b');
  });

  test('getTotalInjectionCount returns number of logs', () async {
    final now = DateTime.now();
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's1',
      lessonId: 'l1',
      timestamp: now.subtract(const Duration(minutes: 2)),
    );
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's2',
      lessonId: 'l2',
      timestamp: now.subtract(const Duration(minutes: 1)),
    );
    final count =
        await TheoryAutoInjectionLoggerService.instance.getTotalInjectionCount();
    expect(count, 2);
  });

  test('getDailyInjectionCounts groups by day', () async {
    final now = DateTime.now();
    String format(DateTime d) =>
        DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's1',
      lessonId: 'l1',
      timestamp: now.subtract(const Duration(days: 2)),
    );
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's2',
      lessonId: 'l2',
      timestamp: now.subtract(const Duration(days: 1, hours: 2)),
    );
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's3',
      lessonId: 'l3',
      timestamp: now.subtract(const Duration(days: 1)),
    );
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's4',
      lessonId: 'l4',
      timestamp: now,
    );

    final counts = await TheoryAutoInjectionLoggerService.instance
        .getDailyInjectionCounts(days: 3);

    expect(
      counts,
      {
        format(now.subtract(const Duration(days: 2))): 1,
        format(now.subtract(const Duration(days: 1))): 2,
        format(now): 1,
      },
    );
  });

  test('getTopLessonInjections returns most frequent lessons', () async {
    final base = DateTime.now().subtract(const Duration(minutes: 5));
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's1',
      lessonId: 'l1',
      timestamp: base,
    );
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's2',
      lessonId: 'l2',
      timestamp: base.add(const Duration(minutes: 1)),
    );
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's3',
      lessonId: 'l1',
      timestamp: base.add(const Duration(minutes: 2)),
    );
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's4',
      lessonId: 'l3',
      timestamp: base.add(const Duration(minutes: 3)),
    );
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's5',
      lessonId: 'l1',
      timestamp: base.add(const Duration(minutes: 4)),
    );
    await TheoryAutoInjectionLoggerService.instance.logAutoInjection(
      spotId: 's6',
      lessonId: 'l2',
      timestamp: base.add(const Duration(minutes: 5)),
    );

    final top = await TheoryAutoInjectionLoggerService.instance
        .getTopLessonInjections(limit: 2);
    expect(top, {'l1': 3, 'l2': 2});
  });
}
