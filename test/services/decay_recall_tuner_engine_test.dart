import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/booster_tag_history.dart';
import 'package:poker_analyzer/models/recall_success_entry.dart';
import 'package:poker_analyzer/services/booster_adaptation_tuner.dart';
import 'package:poker_analyzer/services/decay_recall_tuner_engine.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/services/recall_success_logger_service.dart';
import 'package:poker_analyzer/services/review_streak_evaluator_service.dart';

class _FakeLogger extends RecallSuccessLoggerService {
  final List<RecallSuccessEntry> list;
  _FakeLogger(this.list) : super._();
  @override
  Future<List<RecallSuccessEntry>> getSuccesses({String? tag}) async {
    if (tag == null) return list;
    return list.where((e) => e.tag == tag).toList();
  }
}

class _FakeStreak extends ReviewStreakEvaluatorService {
  final Map<String, BoosterTagHistory> map;
  const _FakeStreak(this.map);
  @override
  Future<Map<String, BoosterTagHistory>> getTagStats() async => map;
}

class _FakeRetention extends DecayTagRetentionTrackerService {
  final Map<String, double> scores;
  const _FakeRetention(this.scores);
  @override
  Future<Map<String, double>> getAllDecayScores({DateTime? now}) async =>
      scores;
}

class _RecordingTuner extends BoosterAdaptationTuner {
  final Map<String, BoosterAdaptation> saved = {};
  @override
  Future<void> saveAdaptation(String tag, BoosterAdaptation adaptation) async {
    saved[tag] = adaptation;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tune adjusts adaptations per heuristics', () async {
    final now = DateTime.now();
    final tuner = _RecordingTuner();
    final engine = DecayRecallTunerEngine(
      logger: _FakeLogger([
        RecallSuccessEntry(tag: 'a', timestamp: now),
        RecallSuccessEntry(tag: 'a', timestamp: now),
        RecallSuccessEntry(tag: 'b', timestamp: now),
      ]),
      streak: _FakeStreak({
        'a': BoosterTagHistory(
          tag: 'a',
          shownCount: 1,
          startedCount: 0,
          completedCount: 2,
          lastInteraction: now.subtract(const Duration(days: 1)),
        ),
        'b': BoosterTagHistory(
          tag: 'b',
          shownCount: 1,
          startedCount: 0,
          completedCount: 2,
          lastInteraction: now.subtract(const Duration(days: 20)),
        ),
        'c': BoosterTagHistory(
          tag: 'c',
          shownCount: 1,
          startedCount: 0,
          completedCount: 2,
          lastInteraction: now.subtract(const Duration(days: 5)),
        ),
      }),
      retention: _FakeRetention({'a': 10, 'b': 70, 'c': 40}),
      tuner: tuner,
    );

    await engine.tune();

    expect(tuner.saved['a'], BoosterAdaptation.reduce);
    expect(tuner.saved['b'], BoosterAdaptation.increase);
    expect(tuner.saved['c'], BoosterAdaptation.keep);
  });
}
