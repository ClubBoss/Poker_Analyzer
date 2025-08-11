import 'skill_tree_library_service.dart';
import 'skill_tree_node_progress_tracker.dart';

/// Estimates overall progress percentage within a single skill tree track.
class SkillTreePathProgressEstimator {
  final SkillTreeLibraryService library;
  final SkillTreeNodeProgressTracker progress;

  SkillTreePathProgressEstimator({
    SkillTreeLibraryService? library,
    SkillTreeNodeProgressTracker? progress,
  })  : library = library ?? SkillTreeLibraryService.instance,
        progress = progress ?? SkillTreeNodeProgressTracker.instance;

  /// Returns progress for [trackId] as a value from 0 to 100.
  ///
  /// Only nodes that are currently unlocked are considered in the total.
  Future<int> getProgressPercent(String trackId) async {
    if (trackId.isEmpty) return 0;
    // Ensure data is loaded.
    if (library.getAllNodes().isEmpty) {
      await library.reload();
    }
    await progress.isCompleted('');

    final tree = library.getTrack(trackId)?.tree;
    if (tree == null) return 0;

    final completed = progress.completedNodeIds.value
        .where(tree.nodes.containsKey)
        .toSet();

    final unlocked = <String>{};
    for (final node in tree.nodes.values) {
      final opt = (node as dynamic).isOptional == true;
      if (opt) continue;
      if (node.prerequisites.isEmpty ||
          node.prerequisites.every(completed.contains)) {
        unlocked.add(node.id);
      }
    }
    if (unlocked.isEmpty) return 0;

    final done = completed.intersection(unlocked).length;
    final percent = ((done / unlocked.length) * 100).round();
    return percent.clamp(0, 100);
  }
}

