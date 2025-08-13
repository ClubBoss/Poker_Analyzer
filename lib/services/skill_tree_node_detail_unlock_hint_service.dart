import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import 'skill_tree_library_service.dart';
import 'skill_tree_node_progress_tracker.dart';
import 'skill_tree_stage_gate_evaluator.dart';
import 'skill_tree_track_resolver.dart';
import 'skill_tree_unlock_evaluator.dart';

/// Provides hints explaining how to unlock a skill tree node on the detail page.
class SkillTreeNodeDetailUnlockHintService {
  const SkillTreeNodeDetailUnlockHintService({
    this.stageEvaluator = const SkillTreeStageGateEvaluator(),
  });

  final SkillTreeStageGateEvaluator stageEvaluator;

  /// Returns a human‑readable hint for [nodeId] by resolving the node's
  /// containing track and current progress state.
  Future<String?> getHint(String nodeId) async {
    final trackId =
        await SkillTreeTrackResolver.instance.getTrackIdForNode(nodeId);
    if (trackId == null) return null;

    final track = SkillTreeLibraryService.instance.getTrack(trackId)?.tree;
    if (track == null) return null;

    final progress = SkillTreeNodeProgressTracker.instance;
    // Ensure progress is loaded.
    await progress.isCompleted('');
    final completed = progress.completedNodeIds.value;

    final unlockedEval = SkillTreeUnlockEvaluator(progress: progress);
    final unlocked =
        unlockedEval.getUnlockedNodes(track).map((n) => n.id).toSet();

    final node = track.nodes[nodeId];
    if (node == null) return null;

    return getUnlockHint(
      node: node,
      unlocked: unlocked,
      completed: completed,
      track: track,
    );
  }

  /// Returns a human‑readable hint describing how to unlock [node].
  ///
  /// If the node is already unlocked, `null` is returned.
  /// Otherwise the method inspects the track's edges and stage gates to
  /// determine which prerequisite nodes must be completed.
  String? getUnlockHint({
    required SkillTreeNodeModel node,
    required Set<String> unlocked,
    required Set<String> completed,
    required SkillTree track,
  }) {
    if (unlocked.contains(node.id)) return null;

    // Stage gating: check if the node's stage is unlocked.
    if (!stageEvaluator.isStageUnlocked(track, node.level, completed)) {
      final blockers =
          stageEvaluator.getBlockingNodes(track, node.level, completed);
      if (blockers.isNotEmpty) {
        final names = _formatNames(blockers.map((n) => n.title).toList());
        return 'Complete $names to unlock this node';
      }
      return 'Complete previous stages to unlock this node';
    }

    // Determine parent nodes from track edges that are not yet completed.
    final parentNodeIds = <String>[
      for (final n in track.nodes.values)
        if (n.unlockedNodeIds.contains(node.id)) n.id,
    ];

    final blocking = <SkillTreeNodeModel>[
      for (final id in parentNodeIds)
        if (!completed.contains(id)) track.nodes[id]!,
    ];

    if (blocking.isEmpty) return null;

    final names = _formatNames(blocking.map((n) => n.title).toList());
    return 'Complete $names to unlock this node';
  }

  String _formatNames(List<String> titles) {
    if (titles.isEmpty) return '';
    if (titles.length == 1) return titles.first;
    if (titles.length == 2) return '${titles[0]} or ${titles[1]}';
    if (titles.length == 3) {
      return '${titles[0]}, ${titles[1]} or ${titles[2]}';
    }
    return titles.first;
  }
}
