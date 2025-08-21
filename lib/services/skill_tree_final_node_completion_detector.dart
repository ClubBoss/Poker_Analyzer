import '../models/skill_tree.dart';
import 'skill_tree_node_progress_tracker.dart';

/// Detects whether all required nodes in a skill tree are completed.
class SkillTreeFinalNodeCompletionDetector {
  final SkillTreeNodeProgressTracker progress;

  SkillTreeFinalNodeCompletionDetector({SkillTreeNodeProgressTracker? progress})
    : progress = progress ?? SkillTreeNodeProgressTracker.instance;

  /// Returns `true` if all non-optional nodes in [tree] are completed.
  Future<bool> isTreeCompleted(SkillTree tree) async {
    await progress.isCompleted('');
    final completed = progress.completedNodeIds.value;
    for (final node in tree.nodes.values) {
      final opt = (node as dynamic).isOptional;
      if (opt == true) continue;
      if (!completed.contains(node.id)) return false;
    }
    return true;
  }
}
