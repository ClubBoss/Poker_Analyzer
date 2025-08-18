import 'package:test/test.dart';

import 'package:poker_analyzer/services/smart_decay_goal_generator.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/services/recall_success_logger_service.dart';
import 'package:poker_analyzer/services/review_streak_evaluator_service.dart';
import 'package:poker_analyzer/models/goal_recommendation.dart';
import 'package:poker_analyzer/models/booster_tag_history.dart';
import 'package:poker_analyzer/models/recall_success_entry.dart';

class _FakeRetention extends DecayTagRetentionTrackerService {
  final Map<String, double> scores;
  const _FakeRetention(this.scores);
  @override
  Future<Map<String, double>> getAllDecayScores({DateTime? now}) async =>
      scores;
}

class _FakeLogger extends RecallSuccessLoggerService {
  final List<RecallSuccessEntry> entries;
  _FakeLogger(this.entries) : super._();
  @override
  Future<List<RecallSuccessEntry>> getSuccesses({String? tag}) async {
    if (tag == null) return entries;
    return entries.where((e) => e.tag == tag).toList();
  }
}

class _FakeStreak extends ReviewStreakEvaluatorService {
  final Map<String, BoosterTagHistory> stats;
  const _FakeStreak(this.stats);
  @override
  Future<Map<String, BoosterTagHistory>> getTagStats() async => stats;
}

void main() {
  test('recommends top decayed tags', () async {
    final now = DateTime.now();
    final service = SmartDecayGoalGenerator(
      retention: const _FakeRetention({'a': 0.8, 'b': 0.7, 'c': 0.5}),
      logger: _FakeLogger([]),
      streak: _FakeStreak({
        'a': BoosterTagHistory(
          tag: 'a',
          shownCount: 1,
          startedCount: 0,
          completedCount: 1,
          lastInteraction: now.subtract(const Duration(days: 10)),
        ),
        'b': BoosterTagHistory(
          tag: 'b',
          shownCount: 1,
          startedCount: 0,
          completedCount: 1,
          lastInteraction: now.subtract(const Duration(days: 8)),
        ),
        'c': BoosterTagHistory(
          tag: 'c',
          shownCount: 1,
          startedCount: 0,
          completedCount: 1,
          lastInteraction: now.subtract(const Duration(days: 15)),
        ),
      }),
    );

    final List<GoalRecommendation> list = await service
        .recommendDecayRecoveryGoals();
    expect(list.length, 2);
    expect(list.first.type, GoalRecommendationType.decay);
    expect(list.first.tag, 'a');
    expect(list.last.tag, 'b');
  });

  test('filters high success rate tags', () async {
    final now = DateTime.now();
    final service = SmartDecayGoalGenerator(
      retention: const _FakeRetention({'a': 0.8, 'b': 0.7}),
      logger: _FakeLogger([
        RecallSuccessEntry(tag: 'a', timestamp: DateTime.now()),
      ]),
      streak: _FakeStreak({
        'a': BoosterTagHistory(
          tag: 'a',
          shownCount: 1,
          startedCount: 0,
          completedCount: 1,
          lastInteraction: now.subtract(const Duration(days: 10)),
        ),
        'b': BoosterTagHistory(
          tag: 'b',
          shownCount: 5,
          startedCount: 5,
          completedCount: 5,
          lastInteraction: now.subtract(const Duration(days: 10)),
        ),
      }),
    );

    final list = await service.recommendDecayRecoveryGoals();
    expect(list.length, 1);
    expect(list.first.type, GoalRecommendationType.decay);
    expect(list.first.tag, 'b');
  });
}
