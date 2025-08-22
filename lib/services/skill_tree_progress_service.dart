import '../models/skill_tree.dart';

/// Computes global progress metrics for a skill tree.
class SkillTreeProgressService {
  SkillTreeProgressService();

  /// Returns the total number of nodes in [tree].
  int getTotalNodeCount(SkillTree tree) => tree.nodes.length;

  /// Returns how many nodes are unlocked or completed in [tree].
  int getUnlockedNodeCount({
    required SkillTree tree,
    required Set<String> unlockedNodeIds,
    required Set<String> completedNodeIds,
  }) {
    final all = unlockedNodeIds.union(
      completedNodeIds.where(tree.nodes.containsKey).toSet(),
    );
    return all.length;
  }
}
