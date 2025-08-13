import '../models/skill_tree_node_model.dart';

/// Represents the normalized completion state of a skill tree node.
enum SkillTreeNodeState { locked, unlocked, completed, optional }

/// Determines the [SkillTreeNodeState] for a given [SkillTreeNodeModel].
///
/// The evaluation is based on node metadata and player progress:
/// - [SkillTreeNodeState.optional] if the node is marked optional.
/// - [SkillTreeNodeState.completed] if the node has been completed or is
///   implicitly completed by being optional.
/// - [SkillTreeNodeState.unlocked] if the node is unlocked but not completed.
/// - [SkillTreeNodeState.locked] otherwise.
class SkillTreeNodeCompletionStateService {
  const SkillTreeNodeCompletionStateService();

  SkillTreeNodeState getNodeState({
    required SkillTreeNodeModel node,
    required Set<String> unlocked,
    required Set<String> completed,
  }) {
    final isOptional = (node as dynamic).isOptional == true;
    final isCompleted = isOptional || completed.contains(node.id);

    if (isOptional) return SkillTreeNodeState.optional;
    if (isCompleted) return SkillTreeNodeState.completed;
    if (unlocked.contains(node.id)) return SkillTreeNodeState.unlocked;
    return SkillTreeNodeState.locked;
  }
}
