import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import '../models/node_gate_status.dart';
import '../services/skill_tree_lesson_state_overlay_builder.dart';
import '../models/node_completion_status.dart';

/// Simple card widget representing a skill tree node with completion overlay.
class SkillTreeNodeCard extends StatelessWidget {
  final SkillTreeNodeModel node;
  final bool unlocked;
  final bool completed;
  final VoidCallback? onTap;
  final bool justUnlocked;

  const SkillTreeNodeCard({
    super.key,
    required this.node,
    required this.unlocked,
    required this.completed,
    this.onTap,
    this.justUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final overlay = const SkillTreeLessonStateOverlayBuilder().build(
      const NodeGateStatus(isVisible: true, isEnabled: true),
      completed
          ? NodeCompletionStatus.completed
          : NodeCompletionStatus.notStarted,
    );
    Color borderColor;
    if (completed) {
      borderColor = Colors.green;
    } else if (unlocked) {
      borderColor = Theme.of(context).colorScheme.secondary;
    } else {
      borderColor = Colors.grey;
    }

    Widget card = Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Center(
            child: Text(
              node.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Positioned(right: 0, top: 0, child: overlay),
        ],
      ),
    );
    if (justUnlocked) {
      card = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: const Duration(seconds: 3),
        builder: (context, value, child) => Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: value),
                blurRadius: 12 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ),
          child: child,
        ),
        child: card,
      );
    }
    return InkWell(onTap: onTap, child: card);
  }
}
