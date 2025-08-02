import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_stage_badge_evaluator_service.dart';

/// Builds a header widget describing a skill tree stage (level).
class SkillTreeStageHeaderBuilder {
  final SkillTreeStageBadgeEvaluatorService badgeEvaluator;

  const SkillTreeStageHeaderBuilder({
    this.badgeEvaluator = const SkillTreeStageBadgeEvaluatorService(),
  });

  /// Returns a widget displaying metadata for a stage.
  Widget buildHeader({
    required int level,
    required List<SkillTreeNodeModel> nodes,
    required Set<String> unlockedNodeIds,
    required Set<String> completedNodeIds,
    Widget? overlay,
  }) {
    final filtered = nodes
        .where((n) => (n as dynamic).isOptional != true)
        .toList();
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

    Widget? badge;
    if (overlay == null) {
      final badgeType = badgeEvaluator.getBadge(
        nodes: nodes,
        unlocked: unlockedNodeIds,
        completed: completedNodeIds,
      );
      IconData? icon;
      Color? color;
      String? tooltip;
      switch (badgeType) {
        case 'locked':
          icon = Icons.lock_outline;
          color = Colors.grey;
          tooltip = 'Stage locked';
          break;
        case 'in_progress':
          icon = Icons.hourglass_bottom;
          color = Colors.amber;
          tooltip = 'In progress';
          break;
        case 'perfect':
          icon = Icons.verified;
          color = Colors.green;
          tooltip = 'Perfect';
          break;
      }
      if (icon != null && tooltip != null) {
        badge = Positioned(
          right: 0,
          top: 0,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: color, size: 20),
          ),
        );
      }
    }

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
                Text(
                  'Level $level',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                progressBar,
                const SizedBox(height: 4),
                subtitle,
              ],
            ),
          ),
          if (overlay != null) overlay,
          if (badge != null) badge,
        ],
      ),
    );
  }
}
