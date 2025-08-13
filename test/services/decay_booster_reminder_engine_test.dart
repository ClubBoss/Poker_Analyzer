import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/decay_booster_reminder_engine.dart';
import 'package:poker_analyzer/services/booster_queue_service.dart';
import 'package:poker_analyzer/services/user_action_logger.dart';
import 'package:poker_analyzer/services/theory_tag_decay_tracker.dart';

class _FakeDecay extends TheoryTagDecayTracker {
  final Map<String, double> scores;
  _FakeDecay(this.scores);
  @override
  Future<Map<String, double>> computeDecayScores({DateTime? now}) async =>
      scores;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserActionLogger.instance.load();
  });

  test('shows reminder when queue unused and decay high', () async {
    await BoosterQueueService.instance.markUsed(
      time: DateTime.now().subtract(const Duration(days: 8)),
    );
    final engine = DecayBoosterReminderEngine(
      queue: BoosterQueueService.instance,
      decay: _FakeDecay({'a': 60}),
      logger: UserActionLogger.instance,
    );
    final should = await engine.shouldShowReminder(now: DateTime.now());
    expect(should, isTrue);
  });

  test('no reminder if queue used recently', () async {
    await BoosterQueueService.instance.markUsed(time: DateTime.now());
    final engine = DecayBoosterReminderEngine(
      queue: BoosterQueueService.instance,
      decay: _FakeDecay({'a': 60}),
      logger: UserActionLogger.instance,
    );
    final should = await engine.shouldShowReminder(now: DateTime.now());
    expect(should, isFalse);
  });

  test('no reminder if already shown today', () async {
    final now = DateTime.now();
    await BoosterQueueService.instance.markUsed(
      time: now.subtract(const Duration(days: 8)),
    );
    SharedPreferences.setMockInitialValues({
      'decay_booster_reminder_last': now.toIso8601String(),
    });
    final engine = DecayBoosterReminderEngine(
      queue: BoosterQueueService.instance,
      decay: _FakeDecay({'a': 60}),
      logger: UserActionLogger.instance,
    );
    final should = await engine.shouldShowReminder(now: now);
    expect(should, isFalse);
  });
}
