import '../models/learning_path_template_v2.dart';
import 'session_log_service.dart';

/// Determines whether a stage in a learning path is unlocked.
class LearningPathStageGatekeeperService {
  const LearningPathStageGatekeeperService();

  /// Returns `true` if the stage at [index] is unlocked given player progress.
  ///
  /// A stage is considered unlocked when it is the first stage in the path or
  /// the previous stage has been completed. Completion requires both the
  /// minimum number of hands and the required accuracy to be met.
  bool isStageUnlocked({
    required int index,
    required LearningPathTemplateV2 path,
    required SessionLogService logs,
    Set<String> additionalUnlockedStageIds = const {},
  }) {
    if (index == 0) return true;
    if (index < 0 || index >= path.stages.length) return false;
    if (additionalUnlockedStageIds.contains(path.stages[index].id)) return true;
    final prev = path.stages[index - 1];
    final stats = logs.getStats(prev.packId);
    if (stats.handsPlayed < prev.requiredHands) return false;
    return stats.accuracy >= prev.requiredAccuracy;
  }
}

