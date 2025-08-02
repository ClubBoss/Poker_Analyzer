import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_track_node_stage_marker_service.dart';
import 'skill_tree_stage_block_builder.dart';

/// Builds a scrollable list of skill tree stages.
class SkillTreeStageListBuilder {
  final SkillTreeStageBlockBuilder blockBuilder;
  final SkillTreeTrackNodeStageMarkerService stageMarker;

  const SkillTreeStageListBuilder({
    this.blockBuilder = const SkillTreeStageBlockBuilder(),
    this.stageMarker = const SkillTreeTrackNodeStageMarkerService(),
  });

  /// Returns a [ListView] of stage blocks grouped by level.
  Widget build({
    required List<SkillTreeNodeModel> allNodes,
    required Set<String> unlockedNodeIds,
    required Set<String> completedNodeIds,
    void Function(SkillTreeNodeModel node)? onNodeTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    double spacing = 16,
  }) {
    final blocks = stageMarker.build(allNodes);
    final children = <Widget>[];
    for (final block in blocks) {
      final nodes = block.nodes;
      final lvl = block.stageIndex;
      final isUnlocked = nodes.any((n) => unlockedNodeIds.contains(n.id));
      final isCompleted = nodes.every((n) {
        final opt = (n as dynamic).isOptional == true;
        return opt || completedNodeIds.contains(n.id);
      });

      final stageWidget = this.blockBuilder.build(
        level: lvl,
        nodes: nodes,
        unlockedNodeIds: unlockedNodeIds,
        completedNodeIds: completedNodeIds,
        isStageUnlocked: isUnlocked,
        isStageCompleted: isCompleted,
        onNodeTap: onNodeTap,
      );

      children.add(Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: stageWidget,
      ));
    }

    return ListView(padding: padding, children: children);
  }
}
