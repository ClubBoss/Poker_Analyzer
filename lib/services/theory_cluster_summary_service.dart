import '../models/theory_cluster_summary.dart';
import '../models/theory_lesson_cluster.dart';

/// Computes high-level summary metrics for a cluster of theory lessons.
class TheoryClusterSummaryService {
  /// Returns summaries for all [clusters].
  List<TheoryClusterSummary> summarize(List<TheoryLessonCluster> clusters) {
    return [for (final c in clusters) generateSummary(c)];
  }

  /// Builds a summary for a single [cluster].
  TheoryClusterSummary generateSummary(TheoryLessonCluster cluster) {
    final lessons = cluster.lessons;
    final byId = {for (final l in lessons) l.id: l};
    final incoming = <String, int>{for (final l in lessons) l.id: 0};

    for (final l in lessons) {
      for (final next in l.nextIds) {
        if (byId.containsKey(next)) {
          incoming[next] = (incoming[next] ?? 0) + 1;
        }
      }
    }

    final entryPoints = <String>[
      for (final l in lessons)
        if ((incoming[l.id] ?? 0) == 0) l.id
    ];

    final tagCounts = <String, int>{};
    for (final l in lessons) {
      for (final t in l.tags) {
        final trimmed = t.trim();
        if (trimmed.isEmpty) continue;
        tagCounts[trimmed] = (tagCounts[trimmed] ?? 0) + 1;
      }
    }
    final sharedTags =
        tagCounts.entries.where((e) => e.value >= 2).map((e) => e.key).toSet();

    return TheoryClusterSummary(
      size: lessons.length,
      entryPointIds: entryPoints,
      sharedTags: sharedTags,
    );
  }
}
