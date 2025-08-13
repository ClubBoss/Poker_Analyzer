import '../models/learning_path_template_v2.dart';
import '../models/training_attempt.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_stats_service.dart';
import 'adaptive_training_path_engine.dart';
import 'learning_path_progress_service_v2.dart';

class SuggestedNextAction {
  final String stageId;
  final String reason;
  const SuggestedNextAction({required this.stageId, required this.reason});
}

/// Recommends which stage of a learning path should be played next.
class LearningPathAdvancer {
  final AdaptiveTrainingPathEngine engine;
  final LearningPathProgressService progressService;

  const LearningPathAdvancer({
    this.engine = const AdaptiveTrainingPathEngine(),
    this.progressService = const LearningPathProgressService(),
  });

  /// Returns the next stage to train along with a textual reason.
  SuggestedNextAction? getNextAction({
    required List<TrainingPackTemplateV2> allPacks,
    required Map<String, TrainingPackStat> stats,
    required List<TrainingAttempt> attempts,
    required LearningPathTemplateV2 path,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final unlocked = engine
        .getUnlockedStageIds(
          allPacks: allPacks,
          stats: stats,
          attempts: attempts,
          path: path,
        )
        .toSet();
    if (unlocked.isEmpty) return null;

    final attemptsByPack = <String, List<TrainingAttempt>>{};
    for (final a in attempts) {
      attemptsByPack.putIfAbsent(a.packId, () => []).add(a);
    }

    SuggestedNextAction? best;
    double bestScore = double.negativeInfinity;

    void consider(stage) {
      if (!unlocked.contains(stage.id)) return;
      final stat = stats[stage.packId];
      final acc = stat?.accuracy ?? 0.0;
      final last = stat?.last;
      final done = acc >= stage.requiredAccuracy;
      if (done) return;

      double score = 0.0;
      String reason = 'next unlocked stage';

      if (last != null) {
        final days = current.difference(last).inDays;
        score += days.toDouble();
        if (days >= 7) reason = 'confidence decay';
      } else {
        score += 30;
        reason = 'confidence decay';
      }

      if (acc < stage.requiredAccuracy) {
        score += (stage.requiredAccuracy - acc) * 100;
        reason = 'confidence decay';
      }

      final recentMistake = attemptsByPack[stage.packId]?.any((a) =>
              a.accuracy < 0.7 &&
              current.difference(a.timestamp).inDays <= 7) ??
          false;
      if (recentMistake) {
        score += 50;
        reason = 'weakness cluster';
      }

      if (score > bestScore) {
        bestScore = score;
        best = SuggestedNextAction(stageId: stage.id, reason: reason);
      }
    }

    for (final stage in path.stages) {
      consider(stage);
    }

    if (best != null) return best;

    final fallback = progressService
        .computeProgress(allPacks: allPacks, stats: stats, path: path)
        .currentStageId;
    if (fallback != null) {
      return SuggestedNextAction(
          stageId: fallback, reason: 'next unlocked stage');
    }
    return null;
  }
}
