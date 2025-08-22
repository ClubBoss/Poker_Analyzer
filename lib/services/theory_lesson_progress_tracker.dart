import 'mini_lesson_progress_tracker.dart';
import '../models/theory_cluster_summary.dart';
import '../models/theory_mini_lesson_node.dart';

/// Tracks progress of theory mini lessons and computes tag mastery gains.
class TheoryLessonProgressTracker {
  final MiniLessonProgressTracker progress;

  /// Creates a tracker using [progress] to determine completed lessons.
  TheoryLessonProgressTracker({MiniLessonProgressTracker? progress})
    : progress = progress ?? MiniLessonProgressTracker.instance;

  /// Returns completion ratio (0.0 - 1.0) for [lessons].
  Future<double> progressForLessons(List<TheoryMiniLessonNode> lessons) async {
    if (lessons.isEmpty) return 0.0;
    var done = 0;
    for (final l in lessons) {
      if (await progress.isCompleted(l.id)) done++;
    }
    return done / lessons.length;
  }

  /// Returns completion ratio (0.0 - 1.0) for [cluster] using [allLessons].
  Future<double> progressForCluster(
    TheoryClusterSummary cluster,
    Map<String, TheoryMiniLessonNode> allLessons,
  ) async {
    final tagSet = {for (final t in cluster.sharedTags) t.trim().toLowerCase()};
    final lessons = <TheoryMiniLessonNode>[];
    for (final n in allLessons.values) {
      final tags = n.tags.map((e) => e.trim().toLowerCase());
      if (tags.any(tagSet.contains)) lessons.add(n);
    }
    return progressForLessons(lessons);
  }

  /// Computes mastery gain per tag from completed [lessons].
  /// Each completed lesson contributes [gain] to its tags.
  Future<Map<String, double>> computeMasteryGains(
    List<TheoryMiniLessonNode> lessons, {
    double gain = 0.05,
  }) async {
    final deltas = <String, double>{};
    for (final l in lessons) {
      if (!await progress.isCompleted(l.id)) continue;
      for (final t in l.tags) {
        final key = t.trim().toLowerCase();
        if (key.isEmpty) continue;
        deltas.update(key, (v) => v + gain, ifAbsent: () => gain);
      }
    }
    return deltas;
  }
}
