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
    Map<int, GlobalKey>? stageKeys,
    ScrollController? controller,
  }) {
    final blocks = stageMarker.build(allNodes);
    final children = <Widget>[];
    for (final block in blocks) {
      final nodes = block.nodes;
      final lvl = block.stageIndex;
      final stageWidget = this.blockBuilder.build(
        level: lvl,
        nodes: nodes,
        unlockedNodeIds: unlockedNodeIds,
        completedNodeIds: completedNodeIds,
        onNodeTap: onNodeTap,
      );

      final key = stageKeys?[lvl];
      children.add(Padding(
        key: key,
        padding: EdgeInsets.only(bottom: spacing),
        child: stageWidget,
      ));
    }

    return ListView(
      controller: controller,
      padding: padding,
      children: children,
    );
  }
}
