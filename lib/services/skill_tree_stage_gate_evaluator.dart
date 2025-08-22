import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import 'skill_tree_stage_completion_evaluator.dart';

/// Determines whether skill tree stages (levels) are unlocked.
class SkillTreeStageGateEvaluator {
  final SkillTreeStageCompletionEvaluator completionEvaluator;

  SkillTreeStageGateEvaluator({
    SkillTreeStageCompletionEvaluator? completionEvaluator,
  }) : completionEvaluator =
           completionEvaluator ?? const SkillTreeStageCompletionEvaluator();

  /// Returns `true` if [level] is unlocked based on [completedNodeIds].
  bool isStageUnlocked(
    SkillTree tree,
    int level,
    Set<String> completedNodeIds,
  ) {
    if (level == 0) return true;
    final levels = <int>{for (final n in tree.nodes.values) n.level};
    final sorted = levels.toList()..sort();
    for (final lvl in sorted) {
      if (lvl >= level) break;
      if (!completionEvaluator.isStageCompleted(tree, lvl, completedNodeIds)) {
        return false;
      }
    }
    return true;
  }

  /// Returns a sorted list of unlocked levels in [tree].
  List<int> getUnlockedStages(SkillTree tree, Set<String> completedNodeIds) {
    final levels = <int>{for (final n in tree.nodes.values) n.level};
    final sorted = levels.toList()..sort();
    final unlocked = <int>[];
    for (final lvl in sorted) {
      if (isStageUnlocked(tree, lvl, completedNodeIds)) {
        unlocked.add(lvl);
      }
    }
    return unlocked;
  }

  /// Returns nodes from earlier stages that block unlocking of [level].
  List<SkillTreeNodeModel> getBlockingNodes(
    SkillTree tree,
    int level,
    Set<String> completedNodeIds,
  ) {
    final blocking = <SkillTreeNodeModel>[];
    for (final node in tree.nodes.values) {
      if (node.level >= level) continue;
      final opt = (node as dynamic).isOptional == true;
      if (opt) continue;
      if (!completedNodeIds.contains(node.id)) {
        blocking.add(node);
      }
    }
    blocking.sort((a, b) => a.level.compareTo(b.level));
    return blocking;
  }
}
