import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_stage_unlock_overlay_builder.dart';
import 'skill_tree_grid_block_builder.dart';
import 'skill_tree_stage_header_builder.dart';

/// Builds a full visual block for a single skill tree stage (level).
class SkillTreeStageBlockBuilder {
  final SkillTreeGridBlockBuilder gridBuilder;
  final SkillTreeStageHeaderBuilder headerBuilder;
  final SkillTreeStageUnlockOverlayBuilder overlayBuilder;

  const SkillTreeStageBlockBuilder({
    this.gridBuilder = const SkillTreeGridBlockBuilder(),
    this.headerBuilder = const SkillTreeStageHeaderBuilder(),
    this.overlayBuilder = const SkillTreeStageUnlockOverlayBuilder(),
  });

  /// Returns a widget displaying [nodes] for a stage with header and overlay.
  Widget build({
    required int level,
    required List<SkillTreeNodeModel> nodes,
    required Set<String> unlockedNodeIds,
    required Set<String> completedNodeIds,
    required bool isStageUnlocked,
    required bool isStageCompleted,
  }) {
    final header = headerBuilder.buildHeader(
      level: level,
      nodes: nodes,
      completedNodeIds: completedNodeIds,
      overlay: overlayBuilder.buildOverlay(
        level: level,
        isUnlocked: isStageUnlocked,
        isCompleted: isStageCompleted,
      ),
    );

    final grid = SkillTreeGridBlockBuilder(
      positioner: gridBuilder.positioner,
      connectorBuilder: gridBuilder.connectorBuilder,
      headerBuilder: const _EmptyHeaderBuilder(),
    ).build(
      level: level,
      nodes: isStageUnlocked ? nodes : const [],
      unlockedNodeIds: unlockedNodeIds,
      completedNodeIds: completedNodeIds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (isStageUnlocked) ...[
          const SizedBox(height: 8),
          grid,
        ],
      ],
    );
  }
}

class _EmptyHeaderBuilder extends SkillTreeStageHeaderBuilder {
  const _EmptyHeaderBuilder();

  @override
  Widget buildHeader({
    required int level,
    required List<SkillTreeNodeModel> nodes,
    required Set<String> completedNodeIds,
    Widget? overlay,
  }) {
    return const SizedBox.shrink();
  }
}
