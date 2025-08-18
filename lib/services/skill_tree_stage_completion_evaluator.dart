import '../models/skill_tree.dart';

/// Evaluates completion of skill tree stages (levels).
class SkillTreeStageCompletionEvaluator {
  const SkillTreeStageCompletionEvaluator();

  /// Returns `true` if all nodes in [tree] with [level] are completed.
  bool isStageCompleted(
    SkillTree tree,
    int level,
    Set<String> completedNodeIds,
  ) {
    for (final node in tree.nodes.values) {
      if (node.level != level) continue;
      final opt = (node as dynamic).isOptional == true;
      if (opt) continue;
      if (!completedNodeIds.contains(node.id)) return false;
    }
    return true;
  }

  /// Returns a sorted list of levels that are completed in [tree].
  List<int> getCompletedStages(SkillTree tree, Set<String> completedNodeIds) {
    final levels = <int>{for (final n in tree.nodes.values) n.level};
    final completed = <int>[];
    final sortedLevels = levels.toList()..sort();
    for (final lvl in sortedLevels) {
      if (isStageCompleted(tree, lvl, completedNodeIds)) {
        completed.add(lvl);
      }
    }
    return completed;
  }
}
