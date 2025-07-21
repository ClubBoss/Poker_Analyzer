import '../models/learning_path_template_v2.dart';
import '../models/session_log.dart';

/// Service computing learning path progress based on session logs.
class LearningPathProgressTrackerService {
  const LearningPathProgressTrackerService();

  /// Aggregates [logs] by pack id summing correct and mistake counts.
  Map<String, SessionLog> aggregateLogsByPack(List<SessionLog> logs) {
    final result = <String, SessionLog>{};
    for (final log in logs) {
      final existing = result[log.templateId];
      if (existing != null) {
        result[log.templateId] = SessionLog(
          sessionId: existing.sessionId,
          templateId: log.templateId,
          startedAt: existing.startedAt.isBefore(log.startedAt)
              ? existing.startedAt
              : log.startedAt,
          completedAt: existing.completedAt.isAfter(log.completedAt)
              ? existing.completedAt
              : log.completedAt,
          correctCount: existing.correctCount + log.correctCount,
          mistakeCount: existing.mistakeCount + log.mistakeCount,
        );
      } else {
        result[log.templateId] = SessionLog(
          sessionId: log.sessionId,
          templateId: log.templateId,
          startedAt: log.startedAt,
          completedAt: log.completedAt,
          correctCount: log.correctCount,
          mistakeCount: log.mistakeCount,
        );
      }
    }
    return result;
  }

  /// Computes per-stage progress strings in format `X / minHands рук · Y%`.
  Map<String, String> computeProgressStrings(
    LearningPathTemplateV2 path,
    List<SessionLog> logs,
  ) {
    final aggregated = aggregateLogsByPack(logs);
    final result = <String, String>{};
    for (final stage in path.stages) {
      final log = aggregated[stage.packId];
      final hands = (log?.correctCount ?? 0) + (log?.mistakeCount ?? 0);
      final correct = log?.correctCount ?? 0;
      final accuracy = hands == 0 ? 0.0 : correct / hands * 100;
      result[stage.id] =
          '$hands / ${stage.minHands} рук · ${accuracy.toStringAsFixed(0)}%';
    }
    return result;
  }

  /// Returns `true` if all stages in [path] meet completion requirements.
  bool isPathCompleted(
    LearningPathTemplateV2 path,
    Map<String, SessionLog> aggregatedLogs,
  ) {
    for (final stage in path.stages) {
      final log = aggregatedLogs[stage.packId];
      final correct = log?.correctCount ?? 0;
      final mistakes = log?.mistakeCount ?? 0;
      final hands = correct + mistakes;
      if (hands < stage.minHands) return false;
      final accuracy = hands == 0 ? 0.0 : correct / hands * 100;
      if (accuracy < stage.requiredAccuracy) return false;
    }
    return true;
  }
}

