import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/booster_tag_history.dart';
import 'package:poker_analyzer/models/tag_review_task.dart';
import 'package:poker_analyzer/services/booster_adaptation_tuner.dart';
import 'package:poker_analyzer/services/decay_smart_scheduler_service.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/services/review_streak_evaluator_service.dart';

class _FakeRetention extends DecayTagRetentionTrackerService {
  final Map<String, double> scores;
  const _FakeRetention(this.scores);
  @override
  Future<Map<String, double>> getAllDecayScores({DateTime? now}) async =>
      scores;
}

class _FakeTuner extends BoosterAdaptationTuner {
  final Map<String, BoosterAdaptation> map;
  const _FakeTuner(this.map);
  @override
  Future<Map<String, BoosterAdaptation>> loadAdaptations() async => map;
}

class _FakeStreak extends ReviewStreakEvaluatorService {
  final Map<String, BoosterTagHistory> stats;
  const _FakeStreak(this.stats);
  @override
  Future<Map<String, BoosterTagHistory>> getTagStats() async => stats;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prioritizes tags based on decay, adaptation and recency', () async {
    final now = DateTime.now();
    final service = DecaySmartSchedulerService(
      retention: _FakeRetention({'a': 0.5, 'b': 0.9}),
      tuner: _FakeTuner({
        'a': BoosterAdaptation.increase,
        'b': BoosterAdaptation.reduce,
      }),
      streak: _FakeStreak({
        'a': BoosterTagHistory(
          tag: 'a',
          shownCount: 1,
          startedCount: 0,
          completedCount: 1,
          lastInteraction: now.subtract(const Duration(hours: 12)),
        ),
        'b': BoosterTagHistory(
          tag: 'b',
          shownCount: 1,
          startedCount: 0,
          completedCount: 1,
          lastInteraction: now.subtract(const Duration(days: 5)),
        ),
      }),
    );

    final List<TagReviewTask> tasks = await service.generateSchedule();
    expect(tasks.first.tag, 'a');
    expect(tasks[1].tag, 'b');
  });

  test('generateTodayPlan limits number of tags', () async {
    final scores = <String, double>{};
    for (var i = 0; i < 12; i++) {
      scores['t$i'] = 0.8;
    }
    final service = DecaySmartSchedulerService(
      retention: _FakeRetention(scores),
      tuner: const _FakeTuner({}),
      streak: const _FakeStreak({}),
    );
    final plan = await service.generateTodayPlan(maxTags: 5);
    expect(plan.tags.length, 5);
  });
}
