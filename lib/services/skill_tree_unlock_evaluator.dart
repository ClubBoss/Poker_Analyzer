import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import 'skill_tree_node_progress_tracker.dart';

/// Determines which skill tree nodes are currently unlocked based on progress.
class SkillTreeUnlockEvaluator {
  final SkillTreeNodeProgressTracker progress;

  const SkillTreeUnlockEvaluator({SkillTreeNodeProgressTracker? progress})
    : progress = progress ?? SkillTreeNodeProgressTracker.instance;

  /// Returns nodes that are unlocked and not yet completed in [tree].
  List<SkillTreeNodeModel> getUnlockedNodes(SkillTree tree) {
    final completed = progress.completedNodeIds.value;
    final unlocked = <SkillTreeNodeModel>[];
    for (final node in tree.nodes.values) {
      if (completed.contains(node.id)) continue;
      if (node.prerequisites.isEmpty ||
          node.prerequisites.every(completed.contains)) {
        unlocked.add(node);
      }
    }
    return unlocked;
  }
}
