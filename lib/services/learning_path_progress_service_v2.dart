import '../models/learning_path_template_v2.dart';
import '../models/learning_path_progress.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/training_pack_stats_service.dart';
import 'adaptive_training_path_engine.dart';

/// Computes learning path progress based on stored training pack stats.
class LearningPathProgressService {
  LearningPathProgressService();

  /// Computes progress for [path] using [stats] gathered from player's
  /// training sessions and list of all available packs [allPacks].
  LearningPathProgress computeProgress({
    required List<TrainingPackTemplateV2> allPacks,
    required Map<String, TrainingPackStat> stats,
    required LearningPathTemplateV2 path,
  }) {
    const engine = AdaptiveTrainingPathEngine();
    final unlocked = engine
        .getUnlockedStageIds(
          allPacks: allPacks,
          stats: stats,
          attempts: const [],
          path: path,
        )
        .toSet();

    var completed = 0;
    var accSum = 0.0;
    String? currentId;

    for (final stage in path.stages) {
      final acc = stats[stage.packId]?.accuracy ?? 0.0;
      final done = acc >= 0.9; // 90% accuracy threshold
      if (done) {
        completed++;
        accSum += acc * 100; // convert to percentage
      }
      if (currentId == null && unlocked.contains(stage.id) && !done) {
        currentId = stage.id;
      }
    }

    final overallAcc = completed > 0 ? accSum / completed : 0.0;

    return LearningPathProgress(
      completedStages: completed,
      totalStages: path.stages.length,
      overallAccuracy: overallAcc,
      currentStageId: currentId,
    );
  }
}
