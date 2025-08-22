import '../models/learning_path_template_v2.dart';
import '../models/session_log.dart';
import 'learning_path_stage_ui_status_engine.dart';

/// Determines if a stage within a learning path is unlocked.
class LearningPathStageUnlockEngine {
  LearningPathStageUnlockEngine();

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

  /// Computes UI states for stages based on aggregated session logs.
  ///
  /// The first stage is always active. A stage is marked as [LearningStageUIState.done]
  /// when both [LearningPathStageModel.minHands] and [LearningPathStageModel.requiredAccuracy]
  /// requirements are met in [aggregatedLogs]. Only the immediate next stage after
  /// the last completed one is set to [LearningStageUIState.active]; all subsequent
  /// stages are [LearningStageUIState.locked].
  Map<String, LearningStageUIState> computeStageUIStates(
    LearningPathTemplateV2 path,
    Map<String, SessionLog> aggregatedLogs,
  ) {
    final states = <String, LearningStageUIState>{};
    var foundActive = false;
    for (final stage in path.stages) {
      bool done = false;
      if (stage.subStages.isEmpty) {
        final log = aggregatedLogs[stage.packId];
        final correct = log?.correctCount ?? 0;
        final mistakes = log?.mistakeCount ?? 0;
        final hands = correct + mistakes;
        final accuracy = hands == 0 ? 0.0 : correct / hands * 100;
        done = hands >= stage.minHands && accuracy >= stage.requiredAccuracy;
      } else {
        done = true;
        for (final sub in stage.subStages) {
          final log = aggregatedLogs[sub.packId];
          final correct = log?.correctCount ?? 0;
          final mistakes = log?.mistakeCount ?? 0;
          final hands = correct + mistakes;
          final accuracy = hands == 0 ? 0.0 : correct / hands * 100;
          if (hands < sub.minHands) {
            done = false;
            break;
          }
          if (accuracy < sub.requiredAccuracy) {
            done = false;
            break;
          }
        }
      }
      if (done) {
        states[stage.id] = LearningStageUIState.done;
        continue;
      }
      if (!foundActive) {
        states[stage.id] = LearningStageUIState.active;
        foundActive = true;
      } else {
        states[stage.id] = LearningStageUIState.locked;
      }
    }
    return states;
  }
}
