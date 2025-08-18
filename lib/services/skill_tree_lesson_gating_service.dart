import '../models/skill_tree.dart';
import '../models/node_gate_status.dart';
import 'skill_tree_track_progress_service.dart';

/// Determines visibility and enablement of nodes in a [SkillTree].
class SkillTreeLessonGatingService {
  final SkillTreeTrackProgressService progressService;

  SkillTreeLessonGatingService({SkillTreeTrackProgressService? progressService})
    : progressService = progressService ?? SkillTreeTrackProgressService();

  /// Returns a mapping of node id to its [NodeGateStatus].
  Future<Map<String, NodeGateStatus>> evaluate(SkillTree tree) async {
    final tracker = progressService.progress;
    // Ensure progress is loaded.
    await tracker.isCompleted('');
    final completed = tracker.completedNodeIds.value;

    final result = <String, NodeGateStatus>{};

    NodeGateStatus computeStatus(String id) {
      final cached = result[id];
      if (cached != null) return cached;
      final node = tree.nodes[id];
      if (node == null) {
        return const NodeGateStatus(isVisible: false, isEnabled: false);
      }
      if (node.prerequisites.isEmpty) {
        final status = const NodeGateStatus(isVisible: true, isEnabled: true);
        result[id] = status;
        return status;
      }
      final visible = tree
          .ancestorsOf(id)
          .every((a) => computeStatus(a.id).isVisible);
      final enabled = node.prerequisites.every(completed.contains);
      final status = NodeGateStatus(isVisible: visible, isEnabled: enabled);
      result[id] = status;
      return status;
    }

    for (final id in tree.nodes.keys) {
      computeStatus(id);
    }

    return result;
  }
}
