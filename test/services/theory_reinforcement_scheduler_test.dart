import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_reinforcement_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('registerSuccess schedules longer interval', () async {
    final sched = TheoryReinforcementScheduler.instance;
    await sched.registerSuccess('l1');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_schedule')!;
    final data = jsonDecode(raw) as Map;
    final entry = data['l1'] as Map<String, dynamic>;
    expect(entry['level'], 1);
  });

  test('registerFailure shortens interval', () async {
    final sched = TheoryReinforcementScheduler.instance;
    await sched.registerSuccess('l2');
    await sched.registerSuccess('l2');
    await sched.registerFailure('l2');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_schedule')!;
    final data = jsonDecode(raw) as Map;
    final entry = data['l2'] as Map<String, dynamic>;
    expect(entry['level'], 1);
  });

  test('getDueReviews returns due ids', () async {
    final sched = TheoryReinforcementScheduler.instance;
    await sched.registerSuccess('x1');
    final now = DateTime.now().add(const Duration(days: 4));
    final due = await sched.getDueReviews(now);
    expect(due, contains('x1'));
  });
}
