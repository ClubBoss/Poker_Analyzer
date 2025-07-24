import '../models/training_result.dart';
import '../models/learning_path_stage_model.dart';
import 'weakness_cluster_engine.dart';
import 'tag_mastery_service.dart';

/// Lightweight identifier for a learning stage with associated tags.
class StageID {
  final String id;
  final List<String> tags;

  const StageID(this.id, {this.tags = const []});
}

/// Container for user progress data required by [SmartRecommenderEngine].
class UserProgress {
  final List<TrainingResult> history;

  const UserProgress({required this.history});
}

/// Suggests the next best stage based on user's weaknesses and mastery.
class SmartRecommenderEngine {
  final WeaknessClusterEngine clusterEngine;
  final TagMasteryService masteryService;

  const SmartRecommenderEngine({
    this.clusterEngine = const WeaknessClusterEngine(),
    required this.masteryService,
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

    for (final stage in availableStages) {
      final tags = stage.tags.map((e) => e.toLowerCase());
      if (tags.any(weakTags.contains)) {
        return stage;
      }
    }
    return availableStages.first;
  }
}
