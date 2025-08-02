import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import 'skill_tree_stage_header_widget.dart';

/// Builds a header widget describing a skill tree stage (level).
class SkillTreeStageHeaderBuilder {
  const SkillTreeStageHeaderBuilder();

  /// Returns a widget displaying metadata for a stage.
  Widget buildHeader({
    required int level,
    required List<SkillTreeNodeModel> nodes,
    required Set<String> unlockedNodeIds,
    required Set<String> completedNodeIds,
    Widget? overlay,
  }) {
    return SkillTreeStageHeaderWidget(
      level: level,
      nodes: nodes,
      unlockedNodeIds: unlockedNodeIds,
      completedNodeIds: completedNodeIds,
      overlay: overlay,
    );
  }
}
