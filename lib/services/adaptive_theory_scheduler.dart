import '../models/player_profile.dart';
import '../models/theory_cluster_summary.dart';
import '../models/theory_mini_lesson_node.dart';

/// Recommended lesson result with optional explanation.
class TheoryScheduleResult {
  final String lessonId;
  final String reason;

  const TheoryScheduleResult({required this.lessonId, required this.reason});
}

/// Selects the next best theory lesson based on completed lessons and tags.
class AdaptiveTheoryScheduler {
  const AdaptiveTheoryScheduler();

  /// Picks an unlocked lesson prioritized by cluster relevance and tag overlap.
  TheoryScheduleResult? recommendNextLesson({
    required PlayerProfile profile,
    required List<TheoryClusterSummary> clusters,
    required Map<String, TheoryMiniLessonNode> lessons,
  }) {
    if (lessons.isEmpty) return null;
    final completed = profile.completedLessonIds;

    // Build incoming edge map to determine unlocked nodes.
    final incoming = <String, Set<String>>{
      for (final id in lessons.keys) id: <String>{}
    };
    lessons.forEach((id, node) {
      for (final next in node.nextIds) {
        if (lessons.containsKey(next)) {
          incoming[next]!.add(id);
        }
      }
    });

    final clusterScores = <TheoryClusterSummary, double>{};
    for (final c in clusters) {
      clusterScores[c] = _scoreCluster(c, profile);
    }

    TheoryScheduleResult? best;
    double bestScore = double.negativeInfinity;

    for (final entry in lessons.entries) {
      final id = entry.key;
      final node = entry.value;
      if (completed.contains(id)) continue;
      final preds = incoming[id] ?? const <String>{};
      if (preds.isNotEmpty && !preds.every(completed.contains)) continue;

      final tags = {for (final t in node.tags) t.trim().toLowerCase()}
        ..removeWhere((e) => e.isEmpty);
      double score = 0;

      for (final c in clusters) {
        if (c.entryPointIds.contains(id) ||
            tags.intersection(c.sharedTags).isNotEmpty) {
          score += clusterScores[c] ?? 0;
          break;
        }
      }

      final overlap = tags.intersection(profile.tags);
      score += overlap.length * 2;
      if ((incoming[id]?.isEmpty ?? true)) score += 0.5;

      if (score > bestScore) {
        bestScore = score;
        final reason = overlap.isNotEmpty
            ? 'weak topic match'
            : (incoming[id]?.isEmpty ?? true)
                ? 'new cluster'
                : 'unlocked';
        best = TheoryScheduleResult(lessonId: id, reason: reason);
      }
    }

    return best;
  }

  double _scoreCluster(TheoryClusterSummary c, PlayerProfile profile) {
    final match = c.sharedTags.where(profile.tags.contains).length;
    final gap = c.sharedTags.difference(profile.tags).length;
    final base = match * 2 + gap;
    return base / (c.size == 0 ? 1 : c.size);
  }
}
