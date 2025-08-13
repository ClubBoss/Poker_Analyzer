import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/booster_queue_service.dart';
import 'package:poker_analyzer/services/decay_booster_reminder_orchestrator.dart';
import 'package:poker_analyzer/services/decay_booster_reminder_engine.dart';
import 'package:poker_analyzer/services/review_streak_evaluator_service.dart';
import 'package:poker_analyzer/services/pack_recall_stats_service.dart';
import 'package:poker_analyzer/models/memory_reminder.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';

class _StubDecayEngine extends DecayBoosterReminderEngine {
  final bool result;
  _StubDecayEngine(this.result);
  @override
  Future<bool> shouldShowReminder({DateTime? now}) async => result;
}

class _FakeStreak extends ReviewStreakEvaluatorService {
  final List<String> ids;
  const _FakeStreak(this.ids);
  @override
  Future<List<String>> packsWithBrokenStreaks() async => ids;
}

class _FakeStats extends PackRecallStatsService {
  final List<String> upcoming;
  _FakeStats(this.upcoming);
  @override
  Future<List<String>> upcomingReviewPacks(
          {Duration leadTime = const Duration(days: 3)}) async =>
      upcoming;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BoosterQueueService.instance.clear();
  });

  test('returns decay booster reminder when queue not empty', () async {
    await BoosterQueueService.instance.addSpots([TrainingPackSpot(id: 's1')]);
    final orch = DecayBoosterReminderOrchestrator(
      boosterEngine: _StubDecayEngine(false),
      streak: const _FakeStreak([]),
      recall: _FakeStats([]),
      queue: BoosterQueueService.instance,
    );
    final reminders = await orch.getRankedReminders();
    expect(reminders.first.type, MemoryReminderType.decayBooster);
  });

  test('orders reminders by priority', () async {
    final orch = DecayBoosterReminderOrchestrator(
      boosterEngine: _StubDecayEngine(false),
      streak: const _FakeStreak(['p1']),
      recall: _FakeStats(['p2']),
      queue: BoosterQueueService.instance,
    );
    final reminders = await orch.getRankedReminders();
    expect(reminders.map((e) => e.type).toList(),
        [MemoryReminderType.brokenStreak, MemoryReminderType.upcomingReview]);
  });
}
