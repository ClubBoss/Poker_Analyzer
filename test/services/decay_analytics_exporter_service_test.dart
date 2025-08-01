import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/booster_tag_history.dart';
import 'package:poker_analyzer/services/booster_adaptation_tuner.dart';
import 'package:poker_analyzer/services/decay_analytics_exporter_service.dart';
import 'package:poker_analyzer/services/decay_review_frequency_advisor_service.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/services/review_streak_evaluator_service.dart';

class _FakeRetention extends DecayTagRetentionTrackerService {
  final Map<String, double> map;
  const _FakeRetention(this.map);
  @override
  Future<Map<String, double>> getAllDecayScores({DateTime? now}) async => map;
}

class _FakeTuner extends BoosterAdaptationTuner {
  final Map<String, BoosterAdaptation> map;
  const _FakeTuner(this.map);
  @override
  Future<Map<String, BoosterAdaptation>> loadAdaptations() async => map;
}

class _FakeStreak extends ReviewStreakEvaluatorService {
  final Map<String, BoosterTagHistory> map;
  const _FakeStreak(this.map);
  @override
  Future<Map<String, BoosterTagHistory>> getTagStats() async => map;
}

class _FakeAdvisor extends DecayReviewFrequencyAdvisorService {
  final List<TagReviewAdvice> list;
  const _FakeAdvisor(this.list);
  @override
  Future<List<TagReviewAdvice>> getAdvice() async => list;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exports analytics sorted by decay', () async {
    final now = DateTime.now();
    final service = DecayAnalyticsExporterService(
      retention: const _FakeRetention({'a': 0.6, 'b': 0.9}),
      tuner: const _FakeTuner({'a': BoosterAdaptation.increase}),
      streak: _FakeStreak({
        'a': BoosterTagHistory(
          tag: 'a',
          shownCount: 1,
          startedCount: 0,
          completedCount: 1,
          lastInteraction: now.subtract(const Duration(days: 1)),
        ),
      }),
      advisor: const _FakeAdvisor([
        TagReviewAdvice(tag: 'a', decay: 0.6, recommendedDaysUntilReview: 2),
        TagReviewAdvice(tag: 'b', decay: 0.9, recommendedDaysUntilReview: 1),
      ]),
    );

    final list = await service.exportAnalytics();
    expect(list.length, 2);
    expect(list.first.tag, 'b');
    expect(list.first.decay, 0.9);
    expect(list[1].tag, 'a');
    expect(list[1].adaptation, BoosterAdaptation.increase);
    expect(list[1].recommendedDaysUntilReview, 2);
    expect(list[1].lastInteraction, isNotNull);
  });
}
