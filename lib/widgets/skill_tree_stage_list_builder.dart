import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import 'skill_tree_stage_block_builder.dart';

/// Builds a scrollable list of skill tree stages.
class SkillTreeStageListBuilder {
  final SkillTreeStageBlockBuilder blockBuilder;

  const SkillTreeStageListBuilder({
    this.blockBuilder = const SkillTreeStageBlockBuilder(),
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
    final levels = <int, List<SkillTreeNodeModel>>{};
    for (final node in allNodes) {
      levels.putIfAbsent(node.level, () => []).add(node);
    }

    final sortedLevels = levels.keys.toList()..sort();
    final children = <Widget>[];
    for (final lvl in sortedLevels) {
      final nodes = levels[lvl]!;
      final isUnlocked = nodes.any((n) => unlockedNodeIds.contains(n.id));
      final isCompleted = nodes.every((n) {
        final opt = (n as dynamic).isOptional == true;
        return opt || completedNodeIds.contains(n.id);
      });

      final block = blockBuilder.build(
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
        child: block,
      ));
    }

    return ListView(padding: padding, children: children);
  }
}
