import '../models/learning_path_template_v2.dart';

/// Determines if a stage within a learning path is unlocked.
class LearningPathStageUnlockEngine {
  const LearningPathStageUnlockEngine();

  /// Returns `true` if [stageId] is unlocked given the set of
  /// [completedStageIds].
  bool isStageUnlocked(
    LearningPathTemplateV2 path,
    String stageId,
    Set<String> completedStageIds,
  ) {
    for (final stage in path.stages) {
      if (stage.unlocks.contains(stageId) &&
          !completedStageIds.contains(stage.id)) {
        return false;
      }
    }
    return true;
  }
}
