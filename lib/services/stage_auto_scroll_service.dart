import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import 'skill_tree_track_node_stage_marker_service.dart';

/// Service that scrolls to the first incomplete stage block in a track.
class StageAutoScrollService {
  final SkillTreeTrackNodeStageMarkerService stageMarker;

  const StageAutoScrollService({
    this.stageMarker = const SkillTreeTrackNodeStageMarkerService(),
  });

  /// Scrolls to the first stage that is not yet completed.
  Future<void> scrollToFirstIncompleteStage({
    required BuildContext context,
    required ScrollController controller,
    required List<SkillTreeNodeModel> allNodes,
    required Set<String> completedNodeIds,
    required Map<int, GlobalKey> stageKeys,
  }) async {
    // Wait for the next frame so that widget positions are laid out.
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted || !controller.hasClients) return;

    final blocks = stageMarker.build(allNodes);
    for (final block in blocks) {
      final nodes = block.nodes;
      final isCompleted = nodes.every((n) {
        final opt = (n as dynamic).isOptional == true;
        return opt || completedNodeIds.contains(n.id);
      });
      if (!isCompleted) {
        final targetContext = stageKeys[block.stageIndex]?.currentContext;
        if (targetContext != null) {
          await Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        break;
      }
    }
  }
}
