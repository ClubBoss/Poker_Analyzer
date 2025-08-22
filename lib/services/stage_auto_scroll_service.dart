import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import 'skill_tree_track_node_stage_marker_service.dart';
import 'stage_auto_highlight_service.dart';
import 'skill_tree_stage_state_service.dart';

/// Service that scrolls to the first incomplete stage block in a track.
class StageAutoScrollService {
  final SkillTreeTrackNodeStageMarkerService stageMarker;
  final StageAutoHighlightService highlighter;
  final SkillTreeStageStateService stageStateService;

  StageAutoScrollService({
    this.stageMarker = const SkillTreeTrackNodeStageMarkerService(),
    this.highlighter = const StageAutoHighlightService(),
    this.stageStateService = const SkillTreeStageStateService(),
  });

  /// Scrolls to the first stage that is not yet completed.
  Future<void> scrollToFirstIncompleteStage({
    required BuildContext context,
    required ScrollController controller,
    required List<SkillTreeNodeModel> allNodes,
    required Set<String> unlockedNodeIds,
    required Set<String> completedNodeIds,
    required Map<int, GlobalKey> stageKeys,
  }) async {
    // Wait for the next frame so that widget positions are laid out.
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted || !controller.hasClients) return;

    final blocks = stageMarker.build(allNodes);
    for (final block in blocks) {
      final state = stageStateService.getStageState(
        nodes: block.nodes,
        unlocked: unlockedNodeIds,
        completed: completedNodeIds,
      );
      if (state != SkillTreeStageState.completed) {
        final targetContext = stageKeys[block.stageIndex]?.currentContext;
        if (targetContext != null) {
          await Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          await highlighter.highlight(
            stageIndex: block.stageIndex,
            stageKeys: stageKeys,
            context: context,
          );
        }
        break;
      }
    }
  }
}
