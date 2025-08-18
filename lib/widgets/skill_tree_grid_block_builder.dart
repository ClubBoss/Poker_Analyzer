import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_block_node_positioner.dart';
import '../services/skill_tree_path_connector_builder.dart';
import 'skill_tree_stage_header_builder.dart';
import 'skill_tree_node_card.dart';

/// Builds a complete visual block for a single skill tree level.
class SkillTreeGridBlockBuilder {
  final SkillTreeBlockNodePositioner positioner;
  final SkillTreePathConnectorBuilder connectorBuilder;
  final SkillTreeStageHeaderBuilder headerBuilder;

  const SkillTreeGridBlockBuilder({
    this.positioner = const SkillTreeBlockNodePositioner(),
    this.connectorBuilder = const SkillTreePathConnectorBuilder(),
    this.headerBuilder = const SkillTreeStageHeaderBuilder(),
  });

  /// Renders [nodes] of a level inside a column with header and connectors.
  Widget build({
    required int level,
    required List<SkillTreeNodeModel> nodes,
    required Set<String> unlockedNodeIds,
    required Set<String> completedNodeIds,
    Set<String> justUnlockedNodeIds = const {},
    void Function(SkillTreeNodeModel node)? onNodeTap,
    double nodeWidth = 120,
    double nodeHeight = 80,
    double spacing = 16,
  }) {
    final bounds = positioner.calculate(
      nodes: nodes,
      nodeWidth: nodeWidth,
      nodeHeight: nodeHeight,
      spacing: spacing,
      center: true,
    );

    final connectors = connectorBuilder.build(
      nodes: nodes,
      bounds: bounds,
      unlockedNodeIds: unlockedNodeIds,
    );

    final nodeWidgets = <Widget>[];
    for (final node in nodes) {
      final rect = bounds[node.id];
      if (rect == null) continue;
      nodeWidgets.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: SkillTreeNodeCard(
            node: node,
            unlocked: unlockedNodeIds.contains(node.id),
            completed: completedNodeIds.contains(node.id),
            justUnlocked: justUnlockedNodeIds.contains(node.id),
            onTap: onNodeTap == null ? null : () => onNodeTap(node),
          ),
        ),
      );
    }

    final contentHeight = bounds.values
        .map((r) => r.bottom)
        .fold<double>(0, (prev, b) => math.max(prev, b));

    final header = headerBuilder.buildHeader(
      level: level,
      nodes: nodes,
      unlockedNodeIds: unlockedNodeIds,
      completedNodeIds: completedNodeIds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 8),
        SizedBox(
          height: contentHeight,
          child: Stack(children: [...connectors, ...nodeWidgets]),
        ),
      ],
    );
  }
}
