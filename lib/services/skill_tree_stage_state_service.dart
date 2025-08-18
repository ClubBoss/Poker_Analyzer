import '../models/skill_tree_node_model.dart';
import 'skill_tree_node_completion_state_service.dart';

/// Represents aggregated state for a skill tree stage.
enum SkillTreeStageState { locked, unlocked, completed }

/// Determines the [SkillTreeStageState] for a set of nodes belonging to a stage.
class SkillTreeStageStateService {
  final SkillTreeNodeCompletionStateService nodeStateService;

  const SkillTreeStageStateService({
    this.nodeStateService = const SkillTreeNodeCompletionStateService(),
  });

  SkillTreeStageState getStageState({
    required List<SkillTreeNodeModel> nodes,
    required Set<String> unlocked,
    required Set<String> completed,
  }) {
    final states = nodes.map(
      (n) => nodeStateService.getNodeState(
        node: n,
        unlocked: unlocked,
        completed: completed,
      ),
    );

    final isCompleted = states.every(
      (s) =>
          s == SkillTreeNodeState.completed || s == SkillTreeNodeState.optional,
    );
    if (isCompleted) return SkillTreeStageState.completed;

    final isUnlocked = states.any(
      (s) =>
          s == SkillTreeNodeState.unlocked || s == SkillTreeNodeState.completed,
    );
    if (isUnlocked) return SkillTreeStageState.unlocked;

    return SkillTreeStageState.locked;
  }
}
