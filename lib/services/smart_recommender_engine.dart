import '../models/training_result.dart';
import '../models/stage_id.dart';
import 'weakness_tag_resolver.dart';
import 'weakness_cluster_engine.dart';
import 'tag_mastery_service.dart';
import 'package:collection/collection.dart';


/// Container for user progress data required by [SmartRecommenderEngine].
class UserProgress {
  final List<TrainingResult> history;

  const UserProgress({required this.history});
}

/// Suggests the next best stage based on user's weaknesses and mastery.
class SmartRecommenderEngine {
  final WeaknessClusterEngine clusterEngine;
  final TagMasteryService masteryService;
  final WeaknessTagResolver tagResolver;

  const SmartRecommenderEngine({
    this.clusterEngine = const WeaknessClusterEngine(),
    required this.masteryService,
    this.tagResolver = const WeaknessTagResolver(),
  });

  Future<StageID?> suggestNextStage({
    required UserProgress progress,
    required List<StageID> availableStages,
    double masteryThreshold = 0.7,
  }) async {
    if (availableStages.isEmpty) return null;

    final mastery = await masteryService.computeMastery();
    final clusters = clusterEngine.detectWeaknesses(
      results: progress.history,
      tagMastery: mastery,
    );
    final weakTags = <String>{
      for (final c in clusters) c.tag.toLowerCase(),
      for (final e in mastery.entries)
        if (e.value < masteryThreshold) e.key.toLowerCase(),
    };

    // First, check explicit mappings from tags to stages.
    for (final tag in weakTags) {
      final mapped = tagResolver.resolveRelevantStages(tag);
      for (final target in mapped) {
        final match =
            availableStages.firstWhereOrNull((s) => s.id == target.id);
        if (match != null) return match;
      }
    }

    for (final stage in availableStages) {
      final tags = stage.tags.map((e) => e.toLowerCase());
      if (tags.any(weakTags.contains)) {
        return stage;
      }
    }
    return availableStages.first;
  }
}
