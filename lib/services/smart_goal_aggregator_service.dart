import '../models/goal_recommendation.dart';
import 'smart_decay_goal_generator.dart';
import 'smart_mistake_goal_generator.dart';

/// Combines decay and mistake goal recommendations.
class SmartGoalAggregatorService {
  final SmartDecayGoalGenerator decay;
  final SmartMistakeGoalGenerator mistake;

  SmartGoalAggregatorService({
    SmartDecayGoalGenerator? decay,
    SmartMistakeGoalGenerator? mistake,
  }) : decay = decay ?? SmartDecayGoalGenerator(),
       mistake = mistake ?? SmartMistakeGoalGenerator();

  Future<List<GoalRecommendation>> getRecommendations({int max = 6}) async {
    if (max <= 0) return <GoalRecommendation>[];
    final decayList = await decay.recommendDecayRecoveryGoals(max: max);
    final mistakeList = await mistake.recommendMistakeRecoveryGoals(max: max);
    final res = <GoalRecommendation>[];
    var i = 0;
    while (res.length < max &&
        (i < decayList.length || i < mistakeList.length)) {
      if (i < decayList.length) res.add(decayList[i]);
      if (res.length >= max) break;
      if (i < mistakeList.length) res.add(mistakeList[i]);
      i++;
    }
    return res;
  }
}
