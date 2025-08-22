import '../models/learning_path_template_v2.dart';
import 'learning_path_stage_unlock_engine.dart';

enum LearningStageUIState { locked, active, done }

class LearningPathStageUIStatusEngine {
  final LearningPathStageUnlockEngine unlockEngine;

  LearningPathStageUIStatusEngine({
    LearningPathStageUnlockEngine? unlockEngine,
  }) : unlockEngine = unlockEngine ?? const LearningPathStageUnlockEngine();

  Map<String, LearningStageUIState> computeStageUIStates(
    LearningPathTemplateV2 path,
    Set<String> completedStageIds,
  ) {
    final states = <String, LearningStageUIState>{};
    for (final stage in path.stages) {
      if (completedStageIds.contains(stage.id)) {
        states[stage.id] = LearningStageUIState.done;
      } else if (unlockEngine.isStageUnlocked(
        path,
        stage.id,
        completedStageIds,
      )) {
        states[stage.id] = LearningStageUIState.active;
      } else {
        states[stage.id] = LearningStageUIState.locked;
      }
    }
    return states;
  }
}
