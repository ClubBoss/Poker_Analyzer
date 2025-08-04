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
}
