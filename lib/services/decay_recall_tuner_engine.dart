import 'booster_adaptation_tuner.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'recall_success_logger_service.dart';
import 'review_streak_evaluator_service.dart';

/// Tunes decay speed per tag based on recall success and review frequency.
class DecayRecallTunerEngine {
  final RecallSuccessLoggerService logger;
  final ReviewStreakEvaluatorService streak;
  final DecayTagRetentionTrackerService retention;
  final BoosterAdaptationTuner tuner;

  DecayRecallTunerEngine({
    RecallSuccessLoggerService? logger,
    ReviewStreakEvaluatorService? streak,
    DecayTagRetentionTrackerService? retention,
    BoosterAdaptationTuner? tuner,
  })  : logger = logger ?? RecallSuccessLoggerService.instance,
        streak = streak ?? const ReviewStreakEvaluatorService(),
        retention = retention ?? const DecayTagRetentionTrackerService(),
        tuner = tuner ?? BoosterAdaptationTuner.instance;

  /// Minimum gap considered over-review.
  static const Duration _frequentGap = Duration(days: 2);

  /// Gap indicating tag was neglected for too long.
  static const Duration _longGap = Duration(days: 14);

  /// Computes adaptations and persists them via [BoosterAdaptationTuner].
  Future<void> tune() async {
    final successLogs = await logger.getSuccesses();
    final tagStats = await streak.getTagStats();
    final decayScores = await retention.getAllDecayScores();

    final successMap = <String, int>{};
    for (final e in successLogs) {
      final tag = e.tag.trim().toLowerCase();
      if (tag.isEmpty) continue;
      successMap.update(tag, (v) => v + 1, ifAbsent: () => 1);
    }

    final tags = <String>{
      ...successMap.keys,
      ...tagStats.keys,
      ...decayScores.keys,
    }..removeWhere((t) => t.isEmpty);

    final now = DateTime.now();

    for (final tag in tags) {
      final stats = tagStats[tag];
      final completed = stats?.completedCount ?? 0;
      final successes = successMap[tag] ?? 0;
      final successRate = completed > 0
          ? successes * 100 / completed
          : (successes > 0 ? 100 : 0);

      final last = stats?.lastInteraction;
      final daysSince = last != null ? now.difference(last).inDays : 999;
      final decay = decayScores[tag] ?? 0.0;

      final tooFrequent = daysSince <= _frequentGap.inDays && decay < 30;
      final longDelay = daysSince >= _longGap.inDays || decay > 60;

      BoosterAdaptation adaptation = BoosterAdaptation.keep;
      if (successRate > 90 && tooFrequent) {
        adaptation = BoosterAdaptation.reduce;
      } else if (successRate < 60 || longDelay) {
        adaptation = BoosterAdaptation.increase;
      }

      await tuner.saveAdaptation(tag, adaptation);
    }
  }
}
