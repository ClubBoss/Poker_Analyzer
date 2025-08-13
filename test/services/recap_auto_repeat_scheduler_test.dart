import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/recap_auto_repeat_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapAutoRepeatScheduler.instance.resetForTest();
  });

  test('scheduleRepeat persists entry', () async {
    final sched = RecapAutoRepeatScheduler.instance;
    await sched.scheduleRepeat('l1', const Duration(days: 2));
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('recap_auto_repeat_schedule');
    expect(raw, isNotNull);
    final data = jsonDecode(raw!) as Map;
    expect(data.containsKey('l1'), isTrue);
  });

  test('getPendingRecapIds yields due id and clears', () async {
    final sched = RecapAutoRepeatScheduler.instance;
    await sched.scheduleRepeat('l2', Duration.zero);
    final ids = await sched
        .getPendingRecapIds(interval: const Duration(seconds: 1))
        .first;
    expect(ids, ['l2']);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('recap_auto_repeat_schedule');
    if (raw != null) {
      final data = jsonDecode(raw) as Map;
      expect(data.containsKey('l2'), isFalse);
    }
  });
}
