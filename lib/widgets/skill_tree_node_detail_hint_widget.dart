import 'package:flutter/material.dart';

import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_node_detail_unlock_hint_service.dart';

/// Small UI component that shows why a skill tree node is locked.
class SkillTreeNodeDetailHintWidget extends StatelessWidget {
  final SkillTreeNodeModel node;
  final SkillTree track;
  final Set<String> unlocked;
  final Set<String> completed;

  const SkillTreeNodeDetailHintWidget({
    super.key,
    required this.node,
    required this.track,
    required this.unlocked,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final hint = const SkillTreeNodeDetailUnlockHintService().getUnlockHint(
      node: node,
      unlocked: unlocked,
      completed: completed,
      track: track,
    );
    if (hint == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
