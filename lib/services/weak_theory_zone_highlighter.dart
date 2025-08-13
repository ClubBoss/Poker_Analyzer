import '../models/player_profile.dart';
import '../models/theory_cluster_summary.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/weak_theory_tag.dart';
import '../models/weak_cluster_info.dart';

/// Identifies weak theory tags and clusters based on player progress.
class WeakTheoryZoneHighlighter {
  const WeakTheoryZoneHighlighter();

  /// Returns weak tags sorted by [WeakTheoryTag.score] descending.
  List<WeakTheoryTag> detectWeakTags({
    required PlayerProfile profile,
    required Map<String, TheoryMiniLessonNode> lessons,
  }) {
    if (lessons.isEmpty) return [];

    final completed = profile.completedLessonIds;
    final totals = <String, int>{};
    final done = <String, int>{};

    for (final node in lessons.values) {
      final tags = node.tags
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty);
      for (final tag in tags) {
        totals[tag] = (totals[tag] ?? 0) + 1;
        if (completed.contains(node.id)) {
          done[tag] = (done[tag] ?? 0) + 1;
        }
      }
    }

    final result = <WeakTheoryTag>[];
    for (final tag in totals.keys) {
      final total = totals[tag] ?? 0;
      if (total == 0) continue;
      final completedCount = done[tag] ?? 0;
      final accuracy = profile.tagAccuracy[tag] ?? 1.0;
      final coverage = completedCount / total;
      final score = (1 - accuracy) + (1 - coverage);
      result.add(
        WeakTheoryTag(
          tag: tag,
          completedCount: completedCount,
          accuracy: accuracy,
          score: double.parse(score.toStringAsFixed(4)),
        ),
      );
    }

    result.sort((a, b) => b.score.compareTo(a.score));
    return result;
  }

  /// Returns weak clusters sorted by [WeakClusterInfo.score] descending.
  List<WeakClusterInfo> detectWeakClusters({
    required PlayerProfile profile,
    required List<TheoryClusterSummary> clusters,
    required Map<String, TheoryMiniLessonNode> lessons,
  }) {
    if (clusters.isEmpty || lessons.isEmpty) return [];

    final tagScores = {
      for (final t in detectWeakTags(profile: profile, lessons: lessons))
        t.tag: t.score
    };
    final lessonList = lessons.values.toList();
    final result = <WeakClusterInfo>[];

    for (final c in clusters) {
      final clusterLessons = <TheoryMiniLessonNode>[];
      for (final n in lessonList) {
        for (final tag in n.tags) {
          if (c.sharedTags.contains(tag.trim().toLowerCase())) {
            clusterLessons.add(n);
            break;
          }
        }
      }
      if (clusterLessons.isEmpty) continue;
      final total = clusterLessons.length;
      final completed = clusterLessons
          .where((l) => profile.completedLessonIds.contains(l.id))
          .length;
      final coverage = completed / total;
      final scores = c.sharedTags
          .map((t) => tagScores[t.trim().toLowerCase()] ?? 0.0)
          .toList();
      final avg =
          scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
      final score = (1 - coverage) + avg;
      result.add(
        WeakClusterInfo(
          cluster: c,
          coverage: coverage,
          score: double.parse(score.toStringAsFixed(4)),
        ),
      );
    }

    result.sort((a, b) => b.score.compareTo(a.score));
    return result;
  }
}
