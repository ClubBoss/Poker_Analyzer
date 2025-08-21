import '../models/theory_cluster_summary.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/theory_goal.dart';
import 'tag_mastery_service.dart';
import 'theory_lesson_progress_tracker.dart';
import 'theory_milestone_unlocker.dart';

/// Recommends theory learning goals based on cluster progress and tag mastery.
class TheoryGoalRecommender {
  final TheoryLessonProgressTracker progress;
  final TagMasteryService mastery;
  final List<double> thresholds;

  TheoryGoalRecommender({
    TheoryLessonProgressTracker? progress,
    required this.mastery,
    List<double>? thresholds,
  })  : progress = progress ?? const TheoryLessonProgressTracker(),
        thresholds = thresholds ?? TheoryMilestoneUnlocker.thresholds;

  /// Generates up to four theory goals from [clusters] and [lessons].
  Future<List<TheoryGoal>> recommend({
    required List<TheoryClusterSummary> clusters,
    required Map<String, TheoryMiniLessonNode> lessons,
  }) async {
    final goals = <TheoryGoal>[];
    if (clusters.isEmpty || lessons.isEmpty) return goals;

    // Collect cluster progress values.
    final entries = <MapEntry<TheoryClusterSummary, double>>[];
    for (final c in clusters) {
      final p = await progress.progressForCluster(c, lessons);
      if (p >= 1.0) continue; // skip completed clusters
      entries.add(MapEntry(c, p));
    }

    // Sort by closeness to 0.5 (mid progress).
    entries.sort((a, b) {
      final da = (0.5 - a.value).abs();
      final db = (0.5 - b.value).abs();
      return da.compareTo(db);
    });

    for (final e in entries) {
      if (goals.length >= 2) break; // only 1-2 cluster goals
      final prog = e.value;
      if (prog < 0.25 || prog > 0.75) continue; // prefer mid progress
      final next = thresholds.firstWhere((t) => t > prog, orElse: () => 1.0);
      if (next <= prog) continue;
      final name =
          e.key.sharedTags.isNotEmpty ? e.key.sharedTags.join(', ') : 'cluster';
      goals.add(
        TheoryGoal(
          title: '📚 Заверши кластер $name до ${(next * 100).round()}%',
          description: 'Текущий прогресс: ${(prog * 100).round()}% из 100%',
          tagOrCluster: name,
          targetProgress: next,
        ),
      );
    }

    // Tag mastery goals.
    final masteryMap = await mastery.computeMastery();
    final tagEntries = masteryMap.entries.where((e) => e.value < 0.75).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    var added = 0;
    for (final e in tagEntries) {
      if (added >= 2) break;
      final current = e.value;
      double target;
      if (current < 0.5) {
        target = 0.5;
      } else if (current < 0.75) {
        target = 0.75;
      } else {
        continue;
      }
      if (target <= current) continue;
      goals.add(
        TheoryGoal(
          title: '📈 Поднять мастерство ${e.key} до ${(target * 100).round()}%',
          description: 'Текущий уровень: ${(current * 100).round()}% из 100%',
          tagOrCluster: e.key,
          targetProgress: target,
        ),
      );
      added++;
    }

    return goals;
  }
}
