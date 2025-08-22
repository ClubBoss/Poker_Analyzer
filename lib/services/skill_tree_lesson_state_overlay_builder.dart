import 'package:flutter/material.dart';

import '../models/node_gate_status.dart';
import '../models/node_completion_status.dart';

/// Builds overlay widgets showing lesson state for skill tree nodes.
class SkillTreeLessonStateOverlayBuilder {
  SkillTreeLessonStateOverlayBuilder();

  /// Returns a list of small overlay widgets for the node's top right corner.
  List<Widget> build(NodeGateStatus gate, NodeCompletionStatus completion) {
    final widgets = <Widget>[];
    if (completion.isCompleted) {
      widgets.add(
        Icon(Icons.check_circle, color: Colors.green, size: 18),
      );
    } else if (!gate.isEnabled) {
      widgets.add(const Icon(Icons.lock, color: Colors.grey, size: 18));
    } else if (completion == NodeCompletionStatus.inProgress) {
      widgets.add(
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return widgets;
  }

  /// Convenience method used in widget previews.
  Widget buildOverlay(NodeGateStatus gate, bool isCompleted) {
    final status = isCompleted
        ? NodeCompletionStatus.completed
        : NodeCompletionStatus.notStarted;
    final list = build(gate, status);
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: list,
    );
  }
}
