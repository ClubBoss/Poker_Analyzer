import 'skill_tree_node_progress_tracker.dart';

/// Evaluates whether a track is locked based on prerequisite completion.
class TrackLockEvaluator {
  final SkillTreeNodeProgressTracker progress;
  final Map<String, String> prerequisites;

  TrackLockEvaluator({
    SkillTreeNodeProgressTracker? progress,
    Map<String, String>? prerequisites,
  })  : progress = progress ?? SkillTreeNodeProgressTracker.instance,
        prerequisites = prerequisites ?? const {};

  /// Returns `true` if [trackId] has a prerequisite that is not yet completed.
  Future<bool> isLocked(String trackId) async {
    final prereq = prerequisites[trackId];
    if (prereq == null) return false;
    return !(await progress.isTrackCompleted(prereq));
  }

  /// Returns all track IDs that are currently unlocked.
  Future<List<String>> getUnlockedTracks() async {
    final ids = <String>{...prerequisites.keys, ...prerequisites.values};
    final unlocked = <String>[];
    for (final id in ids) {
      if (!await isLocked(id)) {
        unlocked.add(id);
      }
    }
    return unlocked;
  }
}
