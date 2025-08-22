import '../models/learning_path_template_v2.dart';
import '../models/session_log.dart';

/// Service computing learning path progress based on session logs.
class LearningPathProgressTrackerService {
  LearningPathProgressTrackerService();

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
          tags: {...existing.tags, ...log.tags}.toList(),
        );
      } else {
        result[log.templateId] = SessionLog(
          sessionId: log.sessionId,
          templateId: log.templateId,
          startedAt: log.startedAt,
          completedAt: log.completedAt,
          correctCount: log.correctCount,
          mistakeCount: log.mistakeCount,
          tags: List<String>.from(log.tags),
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
      if (stage.subStages.isEmpty) {
        final log = aggregated[stage.packId];
        final hands = (log?.correctCount ?? 0) + (log?.mistakeCount ?? 0);
        final correct = log?.correctCount ?? 0;
        final accuracy = hands == 0 ? 0.0 : correct / hands * 100;
        result[stage.id] =
            '$hands / ${stage.minHands} рук · ${accuracy.toStringAsFixed(0)}%';
      } else {
        var hands = 0;
        var minHands = 0;
        double accSum = 0;
        for (final sub in stage.subStages) {
          final log = aggregated[sub.packId];
          final h = (log?.correctCount ?? 0) + (log?.mistakeCount ?? 0);
          final correct = log?.correctCount ?? 0;
          final acc = h == 0 ? 0.0 : correct / h * 100;
          hands += h;
          minHands += sub.minHands;
          accSum += acc;
        }
        final accAvg = stage.subStages.isEmpty
            ? 0.0
            : accSum / stage.subStages.length;
        result[stage.id] =
            '$hands / $minHands рук · ${accAvg.toStringAsFixed(0)}%';
      }
    }
    return result;
  }

  /// Returns `true` if all stages in [path] meet completion requirements.
  bool isPathCompleted(
    LearningPathTemplateV2 path,
    Map<String, SessionLog> aggregatedLogs,
  ) {
    for (final stage in path.stages) {
      if (stage.subStages.isEmpty) {
        final log = aggregatedLogs[stage.packId];
        final correct = log?.correctCount ?? 0;
        final mistakes = log?.mistakeCount ?? 0;
        final hands = correct + mistakes;
        if (hands < stage.minHands) return false;
        final accuracy = hands == 0 ? 0.0 : correct / hands * 100;
        if (accuracy < stage.requiredAccuracy) return false;
      } else {
        for (final sub in stage.subStages) {
          final log = aggregatedLogs[sub.packId];
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
