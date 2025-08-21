import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/memory_reminder.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/adaptive_pack_inbox_notifier.dart';
import 'package:poker_analyzer/services/adaptive_pack_recommender_service.dart';
import 'package:poker_analyzer/services/decay_booster_reminder_orchestrator.dart';
import 'package:poker_analyzer/services/inbox_booster_tracker_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class _FakeOrchestrator extends DecayBoosterReminderOrchestrator {
  final List<MemoryReminder> reminders;
  _FakeOrchestrator(this.reminders);
  @override
  Future<List<MemoryReminder>> getRankedReminders() async => reminders;
}

class _FakeRecommender extends AdaptivePackRecommenderService {
  final List<AdaptivePackRecommendation> recs;
  _FakeRecommender(this.recs) : super(masteryService: _FakeMastery());
  @override
  Future<List<AdaptivePackRecommendation>> recommend({
    int count = 3,
    DateTime? now,
  }) async =>
      recs.take(count).toList();
}

class _FakeMastery extends TagMasteryService {
  _FakeMastery()
      : super(logs: SessionLogService(sessions: TrainingSessionService()));
  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async => {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InboxBoosterTrackerService.instance.resetForTest();
  });

  TrainingPackTemplateV2 pack(String id) => TrainingPackTemplateV2(
        id: id,
        name: id,
        trainingType: TrainingType.pushFold,
      );

  test('adds high score pack to inbox', () async {
    final recs = [AdaptivePackRecommendation(pack: pack('p1'), score: 4.5)];
    final notifier = AdaptivePackInboxNotifier(
      recommender: _FakeRecommender(recs),
      orchestrator: _FakeOrchestrator([]),
      inbox: InboxBoosterTrackerService.instance,
      cooldown: Duration.zero,
    );
    await notifier.start();
    final queue = await InboxBoosterTrackerService.instance.getInbox();
    expect(queue, contains('pack:p1'));
  });

  test('skips when memory reminders exist', () async {
    final recs = [AdaptivePackRecommendation(pack: pack('p1'), score: 4.5)];
    final notifier = AdaptivePackInboxNotifier(
      recommender: _FakeRecommender(recs),
      orchestrator: _FakeOrchestrator([
        const MemoryReminder(
          type: MemoryReminderType.decayBooster,
          priority: 3,
        ),
      ]),
      inbox: InboxBoosterTrackerService.instance,
      cooldown: Duration.zero,
    );
    await notifier.start();
    final queue = await InboxBoosterTrackerService.instance.getInbox();
    expect(queue, isEmpty);
  });
}
