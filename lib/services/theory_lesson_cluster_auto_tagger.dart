import '../models/theory_lesson_cluster.dart';

/// Suggests representative tags for [TheoryLessonCluster]s based on the
/// frequency of tags across all lessons in each cluster.
class TheoryLessonClusterAutoTagger {
  /// Assigns the top [count] most common tags from each cluster's lessons to
  /// [TheoryLessonCluster.autoTags].
  void tagClusters(List<TheoryLessonCluster> clusters, {int count = 3}) {
    for (final cluster in clusters) {
      cluster.autoTags = _topTags(cluster, count);
    }
  }

  /// Returns the top [count] tags for a single [cluster].
  List<String> _topTags(TheoryLessonCluster cluster, int count) {
    final frequencies = <String, int>{};
    for (final lesson in cluster.lessons) {
      for (final tag in lesson.tags) {
        final trimmed = tag.trim();
        if (trimmed.isEmpty) continue;
        frequencies[trimmed] = (frequencies[trimmed] ?? 0) + 1;
      }
    }

    final sorted = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in sorted.take(count)) e.key];
  }
}
