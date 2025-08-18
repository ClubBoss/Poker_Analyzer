import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/goal_recommendation.dart';
import 'package:poker_analyzer/services/smart_goal_aggregator_service.dart';
import 'package:poker_analyzer/services/smart_decay_goal_generator.dart';
import 'package:poker_analyzer/services/smart_mistake_goal_generator.dart';

class _FakeDecay extends SmartDecayGoalGenerator {
  final List<GoalRecommendation> list;
  _FakeDecay(this.list);
  @override
  Future<List<GoalRecommendation>> recommendDecayRecoveryGoals({
    int max = 5,
  }) async => list;
}

class _FakeMistake extends SmartMistakeGoalGenerator {
  final List<GoalRecommendation> list;
  _FakeMistake(this.list);
  @override
  Future<List<GoalRecommendation>> recommendMistakeRecoveryGoals({
    int max = 5,
    int minMistakes = 3,
    double evLossThreshold = 1.0,
  }) async => list;
}

void main() {
  test('interleaves decay and mistake recommendations', () async {
    final decay = _FakeDecay([
      const GoalRecommendation(
        tag: 'd1',
        reason: 'r',
        type: GoalRecommendationType.decay,
      ),
      const GoalRecommendation(
        tag: 'd2',
        reason: 'r',
        type: GoalRecommendationType.decay,
      ),
    ]);
    final mistake = _FakeMistake([
      const GoalRecommendation(
        tag: 'm1',
        reason: 'r',
        type: GoalRecommendationType.mistake,
      ),
    ]);
    final service = SmartGoalAggregatorService(decay: decay, mistake: mistake);
    final list = await service.getRecommendations(max: 3);
    expect(list.length, 3);
    expect(list[0].tag, 'd1');
    expect(list[1].tag, 'm1');
    expect(list[2].tag, 'd2');
  });
}
