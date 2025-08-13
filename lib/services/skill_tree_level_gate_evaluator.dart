import '../models/skill_tree.dart';
import 'skill_tree_node_progress_tracker.dart';

/// Evaluates skill tree level unlocks based on node completion.
class SkillTreeLevelGateEvaluator {
  final SkillTree tree;
  final SkillTreeNodeProgressTracker progress;

  SkillTreeLevelGateEvaluator({
    required this.tree,
    SkillTreeNodeProgressTracker? progress,
  }) : progress = progress ?? SkillTreeNodeProgressTracker.instance;

  /// Returns `true` if [level] is unlocked.
  Future<bool> isLevelUnlocked(int level) async {
    if (level <= 0) return true;
    await progress.isCompleted('');
    final completed = progress.completedNodeIds.value;
    for (final node in tree.nodes.values) {
      if (node.level < level) {
        final opt = (node as dynamic).isOptional;
        if (opt == true) continue;
        if (!completed.contains(node.id)) return false;
      }
    }
    return true;
  }

  /// Returns ids of nodes that block unlocking of [level].
  Future<List<String>> getLockedNodeIds(int level) async {
    await progress.isCompleted('');
    final completed = progress.completedNodeIds.value;
    final locked = <String>[];
    for (final node in tree.nodes.values) {
      if (node.level < level) {
        final opt = (node as dynamic).isOptional;
        if (opt == true) continue;
        if (!completed.contains(node.id)) locked.add(node.id);
      }
    }
    return locked;
  }
}
