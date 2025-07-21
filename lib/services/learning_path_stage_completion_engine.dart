import '../models/learning_path_stage_model.dart';
import '../models/learning_path_template_v2.dart';

/// Determines completion status for learning path stages and entire paths.
class LearningPathStageCompletionEngine {
  const LearningPathStageCompletionEngine();

  /// Returns `true` if [handsPlayed] meets or exceeds [stage.minHands].
  bool isStageComplete(LearningPathStageModel stage, int handsPlayed) {
    return handsPlayed >= stage.minHands;
  }

  /// Returns `true` if all stages in [path] are complete.
  bool isPathComplete(
    LearningPathTemplateV2 path,
    Map<String, int> handsPlayedByPackId,
  ) {
    for (final stage in path.stages) {
      final hands = handsPlayedByPackId[stage.packId] ?? 0;
      if (!isStageComplete(stage, hands)) return false;
    }
    return true;
  }
}
