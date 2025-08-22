import '../models/learning_path_template_v2.dart';
import '../models/session_log.dart';

/// Checks if an entire learning path has been completed based on session logs.
class LearningPathCompletionEngine {
  LearningPathCompletionEngine();

  /// Returns `true` when every stage in [path] has at least the required number
  /// of hands played with sufficient accuracy.
  ///
  /// [logsByPackId] should contain aggregated session data for each pack.
  bool isCompleted(
    LearningPathTemplateV2 path,
    Map<String, SessionLog> logsByPackId,
  ) {
    for (final stage in path.stages) {
      if (stage.subStages.isEmpty) {
        final log = logsByPackId[stage.packId];
        final correct = log?.correctCount ?? 0;
        final mistakes = log?.mistakeCount ?? 0;
        final hands = correct + mistakes;
        if (hands < stage.minHands) return false;
        final accuracy = hands == 0 ? 0.0 : correct / hands * 100;
        if (accuracy < stage.requiredAccuracy) return false;
      } else {
        for (final sub in stage.subStages) {
          final log = logsByPackId[sub.packId];
          final correct = log?.correctCount ?? 0;
          final mistakes = log?.mistakeCount ?? 0;
          final hands = correct + mistakes;
          if (hands < sub.minHands) return false;
          final accuracy = hands == 0 ? 0.0 : correct / hands * 100;
          if (accuracy < sub.requiredAccuracy) return false;
        }
      }
    }
    return true;
  }
}
