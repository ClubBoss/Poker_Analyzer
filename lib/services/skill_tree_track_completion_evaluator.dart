import 'skill_tree_library_service.dart';
import 'skill_tree_node_progress_tracker.dart';

/// Evaluates whether a skill tree track is completed based on node completion.
class SkillTreeTrackCompletionEvaluator {
  final SkillTreeLibraryService library;
  final SkillTreeNodeProgressTracker progress;

  SkillTreeTrackCompletionEvaluator({
    SkillTreeLibraryService? library,
    SkillTreeNodeProgressTracker? progress,
  }) : library = library ?? SkillTreeLibraryService.instance,
       progress = progress ?? SkillTreeNodeProgressTracker.instance;

  Future<void> _ensureLoaded() async {
    if (library.getAllNodes().isEmpty) {
      await library.reload();
    }
    await progress.isCompleted('');
  }

  /// Returns `true` if all non-optional nodes in [trackId] are completed.
  Future<bool> isCompleted(String trackId) async {
    await _ensureLoaded();
    final tree = library.getTrack(trackId)?.tree;
    if (tree == null) return false;
    final completed = progress.completedNodeIds.value;
    for (final node in tree.nodes.values) {
      final opt = (node as dynamic).isOptional == true;
      if (opt) continue;
      if (!completed.contains(node.id)) return false;
    }
    return true;
  }

  /// Returns completion rate (0.0-1.0) for [trackId].
  Future<double> getCompletionRate(String trackId) async {
    await _ensureLoaded();
    final tree = library.getTrack(trackId)?.tree;
    if (tree == null) return 0.0;
    final completed = progress.completedNodeIds.value;
    var total = 0;
    var done = 0;
    for (final node in tree.nodes.values) {
      final opt = (node as dynamic).isOptional == true;
      if (opt) continue;
      total++;
      if (completed.contains(node.id)) done++;
    }
    return total == 0 ? 0.0 : done / total;
  }
}
