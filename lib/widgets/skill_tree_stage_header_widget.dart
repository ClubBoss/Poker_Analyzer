import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import 'skill_tree_stage_header_badge_widget.dart';

/// Displays metadata for a skill tree stage including progress and badge.
class SkillTreeStageHeaderWidget extends StatelessWidget {
  final int level;
  final List<SkillTreeNodeModel> nodes;
  final Set<String> unlockedNodeIds;
  final Set<String> completedNodeIds;
  final Widget? overlay;

  const SkillTreeStageHeaderWidget({
    super.key,
    required this.level,
    required this.nodes,
    required this.unlockedNodeIds,
    required this.completedNodeIds,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final filtered =
        nodes.where((n) => (n as dynamic).isOptional != true).toList();
    final total = filtered.length;
    final done = filtered.where((n) => completedNodeIds.contains(n.id)).length;
    final pct = total > 0 ? ((done / total) * 100).round() : 0;
    final progress = total > 0 ? done / total : 0.0;

    final progressBar = LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.white24,
      minHeight: 6,
    );

    final subtitle = Text(
      '$done of $total completed • $pct%',
      style: const TextStyle(fontSize: 12, color: Colors.white70),
    );

    final badge = overlay == null
        ? SkillTreeStageHeaderBadgeWidget(
            nodes: nodes,
            unlocked: unlockedNodeIds,
            completed: completedNodeIds,
          )
        : null;

    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Level $level',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (badge != null) badge,
                  ],
                ),
                const SizedBox(height: 4),
                progressBar,
                const SizedBox(height: 4),
                subtitle,
              ],
            ),
          ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}
