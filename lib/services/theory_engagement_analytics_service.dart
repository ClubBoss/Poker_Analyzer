import '../models/theory_lesson_engagement_stats.dart';
import 'recall_boost_interaction_logger.dart';
import 'theory_mini_lesson_usage_tracker.dart';
import 'theory_recall_efficiency_evaluator_service.dart';

/// Aggregates usage, view, and success data for theory mini-lessons.
class TheoryEngagementAnalyticsService {
  final TheoryMiniLessonUsageTracker usageTracker;
  final RecallBoostInteractionLogger viewLogger;
  final TheoryRecallEfficiencyEvaluatorService efficiencyService;

  const TheoryEngagementAnalyticsService({
    TheoryMiniLessonUsageTracker? usageTracker,
    RecallBoostInteractionLogger? viewLogger,
    TheoryRecallEfficiencyEvaluatorService? efficiencyService,
  })  : usageTracker = usageTracker ?? TheoryMiniLessonUsageTracker.instance,
        viewLogger = viewLogger ?? RecallBoostInteractionLogger.instance,
        efficiencyService =
            efficiencyService ?? const TheoryRecallEfficiencyEvaluatorService();

  /// Returns aggregated engagement stats for all known theory lessons.
  Future<List<TheoryLessonEngagementStats>> getAllStats() async {
    final manualLogs = await usageTracker.getRecent(limit: 200);
    final manualCounts = <String, int>{};
    for (final e in manualLogs) {
      final id = e.lessonId;
      manualCounts[id] = (manualCounts[id] ?? 0) + 1;
    }

    final viewLogs = await viewLogger.getLogs();
    final viewCounts = <String, int>{};
    for (final v in viewLogs) {
      if (v.durationMs < 1000) continue;
      final id = v.tag;
      viewCounts[id] = (viewCounts[id] ?? 0) + 1;
    }

    final successRates = await efficiencyService.getEfficiencyScoresByTag();

    final ids = <String>{
      ...manualCounts.keys,
      ...viewCounts.keys,
      ...successRates.keys,
    };

    return [
      for (final id in ids)
        TheoryLessonEngagementStats(
          lessonId: id,
          manualOpens: manualCounts[id] ?? 0,
          reviewViews: viewCounts[id] ?? 0,
          successRate: successRates[id] ?? 0.0,
        ),
    ];
  }
}

