import '../models/goal_recommendation.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'recall_success_logger_service.dart';
import 'review_streak_evaluator_service.dart';

/// Generates goal recommendations for decayed theory tags.
class SmartDecayGoalGenerator {
  final DecayTagRetentionTrackerService retention;
  final RecallSuccessLoggerService logger;
  final ReviewStreakEvaluatorService streak;

  SmartDecayGoalGenerator({
    DecayTagRetentionTrackerService? retention,
    RecallSuccessLoggerService? logger,
    ReviewStreakEvaluatorService? streak,
  }) : retention = retention ?? const DecayTagRetentionTrackerService(),
       logger = logger ?? RecallSuccessLoggerService.instance,
       streak = streak ?? const ReviewStreakEvaluatorService();

  /// Returns recommended recovery goals for highly decayed tags.
  Future<List<GoalRecommendation>> recommendDecayRecoveryGoals({
    int max = 5,
  }) async {
    if (max <= 0) return <GoalRecommendation>[];
    final decayScores = await retention.getAllDecayScores();
    final successLogs = await logger.getSuccesses();
    final tagStats = await streak.getTagStats();

    final successMap = <String, int>{};
    for (final log in successLogs) {
      final tag = log.tag.trim().toLowerCase();
      if (tag.isEmpty) continue;
      successMap.update(tag, (v) => v + 1, ifAbsent: () => 1);
    }

    final entries = decayScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final now = DateTime.now();
    final recommendations = <GoalRecommendation>[];

    for (final e in entries) {
      if (recommendations.length >= max) break;
      final tag = e.key;
      final decayPct = (e.value * 100).clamp(0.0, 100.0);
      if (decayPct <= 60) continue;

      final stats = tagStats[tag];
      final daysSince = stats != null
          ? now.difference(stats.lastInteraction).inDays
          : (decayPct).round();
      if (daysSince <= 7) continue;

      final successes = successMap[tag] ?? 0;
      final completed = stats?.completedCount ?? 0;
      final successRate = completed > 0
          ? successes * 100 / completed
          : (successes > 0 ? 100 : 0);
      if (successRate > 90) continue;

      final reason =
          'Decay ${decayPct.round()}%, last review $daysSince days ago';
      recommendations.add(
        GoalRecommendation(
          tag: tag,
          reason: reason,
          type: GoalRecommendationType.decay,
        ),
      );
    }

    return recommendations;
  }
}
