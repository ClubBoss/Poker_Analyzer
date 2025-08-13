import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_stage_badge_evaluator_service.dart';

/// Displays a small badge next to the stage header describing its state.
///
/// It evaluates the stage using [SkillTreeStageBadgeEvaluatorService] and
/// renders one of three icons:
/// - `locked` ➜ grey lock
/// - `in_progress` ➜ amber hourglass
/// - `perfect` ➜ green check circle
class SkillTreeStageHeaderBadgeWidget extends StatelessWidget {
  final List<SkillTreeNodeModel> nodes;
  final Set<String> unlocked;
  final Set<String> completed;

  const SkillTreeStageHeaderBadgeWidget({
    super.key,
    required this.nodes,
    required this.unlocked,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    const evaluator = SkillTreeStageBadgeEvaluatorService();
    final badge = evaluator.getBadge(
      nodes: nodes,
      unlocked: unlocked,
      completed: completed,
    );

    Icon? icon;
    switch (badge) {
      case 'locked':
        icon = const Icon(Icons.lock, color: Colors.grey, size: 18);
        break;
      case 'in_progress':
        icon =
            const Icon(Icons.hourglass_bottom, color: Colors.amber, size: 18);
        break;
      case 'perfect':
        icon = const Icon(Icons.check_circle, color: Colors.green, size: 18);
        break;
    }

    if (icon == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 4),
        icon,
      ],
    );
  }
}
