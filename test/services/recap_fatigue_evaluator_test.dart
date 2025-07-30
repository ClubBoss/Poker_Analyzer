import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/recap_fatigue_evaluator.dart';
import 'package:poker_analyzer/services/recap_history_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapHistoryTracker.instance.resetForTest();
  });

  test('global fatigue after dismissals', () async {
    for (var i = 0; i < 2; i++) {
      await RecapHistoryTracker.instance.logRecapEvent('l$i', 't', 'dismissed');
    }
    final fatigued = await RecapFatigueEvaluator.instance.isFatiguedGlobally();
    expect(fatigued, isTrue);
    final cd = await RecapFatigueEvaluator.instance.recommendedCooldown();
    expect(cd.inHours, greaterThanOrEqualTo(23));
  });

  test('lesson fatigue after repeated dismissals', () async {
    for (var i = 0; i < 3; i++) {
      await RecapHistoryTracker.instance.logRecapEvent(
        'lesson1',
        't',
        'dismissed',
      );
    }
    final fatigued = await RecapFatigueEvaluator.instance.isLessonFatigued(
      'lesson1',
    );
    expect(fatigued, isTrue);
    final cd = await RecapFatigueEvaluator.instance.recommendedCooldown();
    expect(cd.inDays, greaterThanOrEqualTo(2));
  });

  test('global cooldown after many recaps', () async {
    for (var i = 0; i < 5; i++) {
      await RecapHistoryTracker.instance.logRecapEvent('l$i', 't', 'shown');
    }
    final fatigued = await RecapFatigueEvaluator.instance.isFatiguedGlobally();
    expect(fatigued, isTrue);
    final cd = await RecapFatigueEvaluator.instance.recommendedCooldown();
    expect(cd.inHours, inInclusiveRange(11, 12));
  });

  test('isFatigued returns true after 3 dismissals in 24h', () async {
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      await RecapHistoryTracker.instance.logRecapEvent(
        'l$i',
        'banner',
        'dismissed',
        timestamp: now.subtract(Duration(hours: i)),
      );
    }
    final result = await RecapFatigueEvaluator.instance.isFatigued('x');
    expect(result, isTrue);
  });

  test('isFatigued true when same lesson shown recently', () async {
    final now = DateTime.now();
    await RecapHistoryTracker.instance.logRecapEvent(
      'lesson1',
      'banner',
      'shown',
      timestamp: now.subtract(const Duration(hours: 2)),
    );
    final result = await RecapFatigueEvaluator.instance.isFatigued('lesson1');
    expect(result, isTrue);
  });

  test('isFatigued true when lesson completed today', () async {
    await RecapHistoryTracker.instance.logRecapEvent(
      'lesson2',
      'banner',
      'completed',
    );
    final result = await RecapFatigueEvaluator.instance.isFatigued('lesson2');
    expect(result, isTrue);
  });
}
