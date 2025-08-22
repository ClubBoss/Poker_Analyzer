// Computes completion statistics for theory lesson clusters.

import '../models/theory_lesson_cluster.dart';
import '../services/mini_lesson_progress_tracker.dart';

class ClusterProgress {
  final TheoryLessonCluster cluster;
  final int completed;
  final int total;

  ClusterProgress({
    required this.cluster,
    required this.completed,
    required this.total,
  });

  double get percent => total == 0 ? 0 : completed / total;
}

class TheoryClusterProgressService {
  final MiniLessonProgressTracker progress;

  TheoryClusterProgressService({MiniLessonProgressTracker? progress})
    : progress = progress ?? MiniLessonProgressTracker.instance;

  Future<List<ClusterProgress>> computeProgress(
    List<TheoryLessonCluster> clusters,
  ) async {
    final result = <ClusterProgress>[];
    for (final c in clusters) {
      final total = c.lessons.length;
      var done = 0;
      for (final l in c.lessons) {
        if (await progress.isCompleted(l.id)) done++;
      }
      result.add(ClusterProgress(cluster: c, completed: done, total: total));
    }
    return result;
  }
}
