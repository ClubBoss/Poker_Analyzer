import 'learning_graph_engine.dart';
import 'theory_booster_reinjection_policy.dart';

/// Background service that removes ineffective booster nodes from the learning graph.
class AutoBoosterPruner {
  final LearningPathEngine engine;
  final TheoryBoosterReinjectionPolicy policy;

  /// Global toggle for enabling pruning. Useful for tests.
  static bool enabled = true;

  const AutoBoosterPruner({
    LearningPathEngine? engine,
    TheoryBoosterReinjectionPolicy? policy,
  }) : engine = engine ?? LearningPathEngine.instance,
       policy = policy ?? TheoryBoosterReinjectionPolicy.instance;

  /// Scans [boosterNodeIds] and removes those deemed ineffective.
  /// Returns the number of pruned nodes.
  Future<int> pruneLowImpactBoosters(List<String> boosterNodeIds) async {
    if (!enabled) return 0;
    if (boosterNodeIds.isEmpty) return 0;

    var pruned = 0;
    for (final id in boosterNodeIds) {
      if (!await policy.shouldReinject(id)) {
        await engine.removeNode(id);
        pruned++;
      }
    }
    return pruned;
  }
}
