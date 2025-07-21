import '../models/learning_path_template_v2.dart';
import '../models/session_log.dart';

/// Determines whether a stage in a learning path is unlocked.
class LearningPathStageGatekeeperService {
  const LearningPathStageGatekeeperService();

  /// Returns `true` if the stage at [index] is unlocked given [logs].
  ///
  /// A stage is considered unlocked when it is the first stage in the path or
  /// the previous stage has been completed. Completion requires both the
  /// minimum number of hands and the required accuracy to be met.
  bool isStageUnlocked({
    required int index,
    required LearningPathTemplateV2 path,
    required Map<String, SessionLog> logs,
  }) {
    if (index == 0) return true;
    if (index < 0 || index >= path.stages.length) return false;
    final prev = path.stages[index - 1];
    final log = logs[prev.packId];
    final correct = log?.correctCount ?? 0;
    final mistakes = log?.mistakeCount ?? 0;
    final total = correct + mistakes;
    if (total < prev.minHands) return false;
    final accuracy = total == 0 ? 0.0 : correct / total * 100;
    return accuracy >= prev.requiredAccuracy;
  }
}

