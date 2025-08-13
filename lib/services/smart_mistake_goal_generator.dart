import '../models/goal_recommendation.dart';
import 'mistake_analytics_service.dart';
import 'recall_success_logger_service.dart';
import 'review_streak_evaluator_service.dart';

/// Generates goal recommendations from frequent mistakes.
class SmartMistakeGoalGenerator {
  final MistakeAnalyticsService analytics;
  final RecallSuccessLoggerService logger;
  final ReviewStreakEvaluatorService streak;

  SmartMistakeGoalGenerator({
    MistakeAnalyticsService? analytics,
    RecallSuccessLoggerService? logger,
    ReviewStreakEvaluatorService? streak,
  })  : analytics = analytics ?? const MistakeAnalyticsService(),
        logger = logger ?? RecallSuccessLoggerService.instance,
        streak = streak ?? const ReviewStreakEvaluatorService();

  /// Returns recommended recovery goals based on recent mistakes.
  Future<List<GoalRecommendation>> recommendMistakeRecoveryGoals({
    int max = 5,
    int minMistakes = 3,
    double evLossThreshold = 1.0,
  }) async {
    if (max <= 0) return <GoalRecommendation>[];
    final mistakes = await analytics.getTopMistakeTags(max: max * 2);
    final tagStats = await streak.getTagStats();
    final successLogs = await logger.getSuccesses();

    final successMap = <String, int>{};
    for (final log in successLogs) {
      final tag = log.tag.trim().toLowerCase();
      if (tag.isEmpty) continue;
      successMap.update(tag, (v) => v + 1, ifAbsent: () => 1);
    }

    final now = DateTime.now();
    final recommendations = <GoalRecommendation>[];

    for (final data in mistakes) {
      if (recommendations.length >= max) break;
      if (data.mistakeCount <= minMistakes && data.evLoss <= evLossThreshold) {
        continue;
      }
      final stats = tagStats[data.tag];
      final daysSince = stats != null
          ? now.difference(stats.lastInteraction).inDays
          : (data.mistakeCount).round();
      if (daysSince <= 3) continue;

      final successes = successMap[data.tag] ?? 0;
      final completed = stats?.completedCount ?? 0;
      final successRate = completed > 0
          ? successes * 100 / completed
          : (successes > 0 ? 100 : 0);
      if (successRate > 90) continue;

      final reason =
          '${data.mistakeCount} mistakes, EV loss ${data.evLoss.toStringAsFixed(1)}';
      recommendations.add(
        GoalRecommendation(
          tag: data.tag,
          reason: reason,
          type: GoalRecommendationType.mistake,
        ),
      );
    }

    return recommendations;
  }
}
