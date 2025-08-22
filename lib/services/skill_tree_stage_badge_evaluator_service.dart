import '../models/skill_tree_node_model.dart';
import 'skill_tree_stage_state_service.dart';
import 'skill_tree_node_completion_state_service.dart';

/// Assigns visual badges to a skill tree stage based on its state and node progress.
///
/// Returns one of "locked", "in_progress", or "perfect" depending on the
/// aggregated stage state and completion of individual nodes.
class SkillTreeStageBadgeEvaluatorService {
  final SkillTreeStageStateService stageStateService;
  final SkillTreeNodeCompletionStateService nodeStateService;

  SkillTreeStageBadgeEvaluatorService({
    this.stageStateService = const SkillTreeStageStateService(),
    this.nodeStateService = const SkillTreeNodeCompletionStateService(),
  });

  /// Evaluates the badge for the given stage nodes.
  ///
  /// [nodes] are all nodes belonging to the stage.
  /// [unlocked] contains the ids of unlocked nodes.
  /// [completed] contains the ids of completed nodes.
  String getBadge({
    required List<SkillTreeNodeModel> nodes,
    required Set<String> unlocked,
    required Set<String> completed,
  }) {
    final state = stageStateService.getStageState(
      nodes: nodes,
      unlocked: unlocked,
      completed: completed,
    );

    if (state == SkillTreeStageState.locked) {
      return 'locked';
    }

    if (state == SkillTreeStageState.completed) {
      final allCompleted = nodes.every(
        (n) =>
            nodeStateService.getNodeState(
              node: n,
              unlocked: unlocked,
              completed: completed,
            ) ==
            SkillTreeNodeState.completed,
      );
      if (allCompleted) return 'perfect';
    }

    return 'in_progress';
  }
}
