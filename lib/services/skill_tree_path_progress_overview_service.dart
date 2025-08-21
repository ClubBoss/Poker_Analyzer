import 'skill_tree_track_progress_service.dart';

/// Summary information about overall skill tree path progress.
class PathProgressOverview {
  final int totalTracks;
  final int completedTracks;
  final double averageCompletionRate; // 0.0 - 1.0

  const PathProgressOverview({
    required this.totalTracks,
    required this.completedTracks,
    required this.averageCompletionRate,
  });
}

/// Computes aggregated progress across all skill tree tracks.
class SkillTreePathProgressOverviewService {
  final SkillTreeTrackProgressService tracks;

  SkillTreePathProgressOverviewService({SkillTreeTrackProgressService? tracks})
    : tracks = tracks ?? SkillTreeTrackProgressService();

  /// Returns global progress overview for the skill tree learning path.
  Future<PathProgressOverview> computeOverview() async {
    final list = await tracks.getAllTrackProgress();
    final total = list.length;
    if (total == 0) {
      return const PathProgressOverview(
        totalTracks: 0,
        completedTracks: 0,
        averageCompletionRate: 0.0,
      );
    }
    var completed = 0;
    var sumRate = 0.0;
    for (final entry in list) {
      if (entry.isCompleted) completed++;
      sumRate += entry.completionRate;
    }
    final avgRate = sumRate / total;
    return PathProgressOverview(
      totalTracks: total,
      completedTracks: completed,
      averageCompletionRate: avgRate,
    );
  }
}
