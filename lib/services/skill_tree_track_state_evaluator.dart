import 'skill_tree_track_progress_service.dart';

/// Possible states for a skill tree track.
enum SkillTreeTrackState { locked, unlocked, inProgress, completed }

/// Pair of a [TrackProgressEntry] with its current [state].
class TrackStateEntry {
  final TrackProgressEntry progress;
  final SkillTreeTrackState state;

  const TrackStateEntry({required this.progress, required this.state});
}

/// Evaluates the state of each skill tree track based on progress
/// and optional prerequisites.
class SkillTreeTrackStateEvaluator {
  final SkillTreeTrackProgressService progressService;
  final Map<String, List<String>> _prereq;

  SkillTreeTrackStateEvaluator({
    SkillTreeTrackProgressService? progressService,
    Map<String, List<String>>? prerequisites,
  })  : progressService = progressService ?? SkillTreeTrackProgressService(),
        _prereq = prerequisites ?? const {};

  /// Returns a list of [TrackStateEntry] describing the state of each track.
  Future<List<TrackStateEntry>> evaluateStates() async {
    final list = await progressService.getAllTrackProgress();
    if (list.isEmpty) return [];

    final completedCats = <String>{};
    String catOf(TrackProgressEntry e) => e.tree.nodes.values.first.category;

    for (final e in list) {
      if (e.isCompleted) completedCats.add(catOf(e));
    }

    final results = <TrackStateEntry>[];
    for (final entry in list) {
      final cat = catOf(entry);
      final prereq = _prereq[cat] ?? const [];
      final unlocked = prereq.every(completedCats.contains);

      SkillTreeTrackState state;
      if (!unlocked) {
        state = SkillTreeTrackState.locked;
      } else if (entry.isCompleted) {
        state = SkillTreeTrackState.completed;
      } else if (entry.completionRate > 0) {
        state = SkillTreeTrackState.inProgress;
      } else {
        state = SkillTreeTrackState.unlocked;
      }

      results.add(TrackStateEntry(progress: entry, state: state));
    }

    return results;
  }
}
