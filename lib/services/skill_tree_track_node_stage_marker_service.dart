import '../models/skill_tree_node_model.dart';

/// Helper service that groups nodes into visual stage blocks based on level.
class SkillTreeTrackNodeStageMarkerService {
  SkillTreeTrackNodeStageMarkerService();

  /// Groups [nodes] by their level and returns ordered stage blocks.
  List<StageBlock> build(List<SkillTreeNodeModel> nodes) {
    final levels = <int, List<SkillTreeNodeModel>>{};
    for (final node in nodes) {
      levels.putIfAbsent(node.level, () => []).add(node);
    }

    final sortedLevels = levels.keys.toList()..sort();
    return [
      for (final lvl in sortedLevels)
        StageBlock(stageIndex: lvl, nodes: List.unmodifiable(levels[lvl]!)),
    ];
  }
}

/// Container for nodes belonging to the same stage.
class StageBlock {
  final int stageIndex;
  final List<SkillTreeNodeModel> nodes;

  StageBlock({required this.stageIndex, required this.nodes});
}
