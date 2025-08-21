import '../models/theory_mini_lesson_node.dart';
import '../models/theory_cluster_summary.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'booster_library_service.dart';
import 'theory_lesson_tag_clusterer.dart';
import 'theory_cluster_summary_service.dart';
import 'theory_booster_recommender.dart';
import 'theory_replay_cooldown_manager.dart';

/// Links weak theory lessons to relevant booster packs.
class SmartTheoryBoosterBridge {
  final BoosterLibraryService library;
  final TheoryLessonTagClusterer clusterer;
  final TheoryClusterSummaryService summaryService;

  const SmartTheoryBoosterBridge({
    this.library = BoosterLibraryService.instance,
    TheoryLessonTagClusterer? clusterer,
    TheoryClusterSummaryService? summaryService,
  }) : clusterer = clusterer ?? TheoryLessonTagClusterer(),
       summaryService = summaryService ?? TheoryClusterSummaryService();

  /// Returns booster recommendations for [lessons] sorted by score.
  Future<List<BoosterRecommendationResult>> recommend(
    List<TheoryMiniLessonNode> lessons,
  ) async {
    if (lessons.isEmpty) return <BoosterRecommendationResult>[];
    await library.loadAll();
    final boosters = library.all;
    if (boosters.isEmpty) return <BoosterRecommendationResult>[];

    final clusters = await clusterer.clusterLessons();
    final lessonClusters = <String, TheoryClusterSummary>{};
    for (final c in clusters) {
      final summary = summaryService.generateSummary(c);
      for (final l in c.lessons) {
        lessonClusters[l.id] = summary;
      }
    }

    final results = <BoosterRecommendationResult>[];

    for (final lesson in lessons) {
      final tags = {for (final t in lesson.tags) t.trim().toLowerCase()}
        ..removeWhere((t) => t.isEmpty);
      final cluster = lessonClusters[lesson.id];
      final clusterTags = cluster != null
          ? cluster.sharedTags.map((e) => e.trim().toLowerCase()).toSet()
          : <String>{};

      TrainingPackTemplateV2? best;
      String? bestTag;
      double bestScore = 0;

      for (final booster in boosters) {
        final bTags = <String>{
          ...booster.tags.map((e) => e.trim().toLowerCase()),
          if (booster.meta['tag'] != null)
            booster.meta['tag'].toString().toLowerCase(),
        }..removeWhere((t) => t.isEmpty);

        final overlap = bTags.intersection(tags);
        final clusterOverlap = bTags.intersection(clusterTags);
        if (overlap.isEmpty && clusterOverlap.isEmpty) continue;

        var score = overlap.length + clusterOverlap.length;
        if (booster.trainingType == TrainingType.pushFold) {
          score += 0.5;
        }
        if (score > bestScore) {
          best = booster;
          bestScore = score.toDouble();
          bestTag = overlap.isNotEmpty ? overlap.first : clusterOverlap.first;
        }
      }

      if (best != null && bestTag != null) {
        if (await TheoryReplayCooldownManager.isUnderCooldown(bestTag)) {
          continue;
        }
        results.add(
          BoosterRecommendationResult(
            boosterId: best.id,
            reasonTag: bestTag,
            priority: bestScore,
            origin: 'weakTheory',
          ),
        );
      }
    }

    results.sort((a, b) => b.priority.compareTo(a.priority));
    return results;
  }
}
