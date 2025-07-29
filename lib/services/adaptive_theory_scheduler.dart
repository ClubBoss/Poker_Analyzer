import '../models/player_profile.dart';
import '../models/theory_goal.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/theory_lesson_cluster.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/theory_goal_engine.dart';
import '../services/theory_lesson_progress_tracker.dart';
import '../services/theory_lesson_tag_clusterer.dart';
import '../services/theory_cluster_summary_service.dart';
import '../services/weak_theory_zone_highlighter.dart';

/// Service selecting the best next theory lesson based on goals and weaknesses.
class AdaptiveTheoryScheduler {
  final TheoryGoalEngine goalEngine;
  final WeakTheoryZoneHighlighter weakZone;
  final TheoryLessonProgressTracker progress;
  final MiniLessonLibraryService library;
  final TheoryLessonTagClusterer clusterer;
  final TheoryClusterSummaryService summaryService;

  const AdaptiveTheoryScheduler({
    TheoryGoalEngine? goalEngine,
    WeakTheoryZoneHighlighter? weakZone,
    TheoryLessonProgressTracker? progress,
    MiniLessonLibraryService? library,
    TheoryLessonTagClusterer? clusterer,
    TheoryClusterSummaryService? summaryService,
  })  : goalEngine = goalEngine ?? TheoryGoalEngine.instance,
        weakZone = weakZone ?? const WeakTheoryZoneHighlighter(),
        progress = progress ?? const TheoryLessonProgressTracker(),
        library = library ?? MiniLessonLibraryService.instance,
        clusterer = clusterer ?? TheoryLessonTagClusterer(),
        summaryService = summaryService ?? TheoryClusterSummaryService();

  /// Returns the next recommended lesson for [profile], or null if none found.
  Future<TheoryMiniLessonNode?> getNextRecommendedLesson(
    PlayerProfile profile,
  ) async {
    await library.loadAll();
    final lessonsById = {for (final l in library.all) l.id: l};

    // Collect goal tags.
    final goals = await goalEngine.getActiveGoals();
    final goalTags = <String>{};
    for (final g in goals) {
      final parts = g.tagOrCluster
          .split(',')
          .map((e) => e.trim().toLowerCase());
      goalTags.addAll(parts.where((e) => e.isNotEmpty));
    }

    // Detect weak tags.
    final weakTags = weakZone
        .detectWeakTags(profile: profile, lessons: lessonsById)
        .map((e) => e.tag)
        .toList();

    // Build clusters and compute progress per cluster.
    final lessonClusters = await clusterer.clusterLessons();
    final progressByLesson = <String, double>{};
    for (final c in lessonClusters) {
      final p = await progress.progressForLessons(c.lessons);
      for (final l in c.lessons) {
        progressByLesson[l.id] = p;
      }
    }

    // Build incoming edge map to verify unlocks.
    final incoming = <String, Set<String>>{
      for (final l in library.all) l.id: <String>{}
    };
    for (final l in library.all) {
      for (final next in l.nextIds) {
        if (incoming.containsKey(next)) incoming[next]!.add(l.id);
      }
    }

    TheoryMiniLessonNode? best;
    double bestScore = double.negativeInfinity;

    for (final lesson in library.all) {
      final id = lesson.id;
      if (profile.completedLessonIds.contains(id)) continue;
      final preds = incoming[id]!;
      if (preds.isNotEmpty && !preds.every(profile.completedLessonIds.contains)) {
        continue; // Locked
      }

      final tags = lesson.tags
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .toSet();
      if (tags.isEmpty) continue;

      double score = 0;

      // Goal alignment.
      final goalMatches = tags.intersection(goalTags);
      score += goalMatches.length * 5;

      // Weak tag overlap.
      for (var i = 0; i < weakTags.length; i++) {
        if (tags.contains(weakTags[i])) {
          score += (weakTags.length - i).toDouble();
        }
      }

      // Cluster progress.
      final prog = progressByLesson[id] ?? 0.0;
      score += (1 - prog) * 2;

      if (preds.isEmpty) score += 0.5;

      if (score > bestScore) {
        bestScore = score;
        best = lesson;
      }
    }

    return best;
  }
}
