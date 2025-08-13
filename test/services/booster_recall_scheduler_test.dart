import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/booster_recall_scheduler.dart';
import 'package:poker_analyzer/services/booster_completion_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BoosterRecallScheduler.instance.resetForTest();
    BoosterCompletionTracker.instance.resetForTest();
  });

  test('returns boosters sorted by missed count', () async {
    final scheduler = BoosterRecallScheduler.instance;
    final now = DateTime.now();
    await scheduler.markBoosterSkipped('b1');
    await scheduler.markBoosterSkipped('b2');
    await scheduler.markBoosterSkipped('b2');
    final due = await scheduler.getDueBoosters('s1');
    expect(due, ['b2', 'b1']);
  });

  test('only reinjects once per stage', () async {
    final scheduler = BoosterRecallScheduler.instance;
    await scheduler.markBoosterSkipped('b1');
    final first = await scheduler.getDueBoosters('s1');
    final second = await scheduler.getDueBoosters('s1');
    expect(first, ['b1']);
    expect(second, isEmpty);
  });

  test('decays old misses', () async {
    final scheduler = BoosterRecallScheduler.instance;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('booster_recall_scheduler',
        '{"b1": {"c": 1, "t": "2020-01-01T00:00:00.000Z"}}');
    scheduler.resetForTest();
    final due = await scheduler.getDueBoosters('s1');
    expect(due, isEmpty);
  });

  test('ignores completed boosters', () async {
    final scheduler = BoosterRecallScheduler.instance;
    await scheduler.markBoosterSkipped('b1');
    await BoosterCompletionTracker.instance.markBoosterCompleted('b1');
    final due = await scheduler.getDueBoosters('s1');
    expect(due, isEmpty);
  });
}
