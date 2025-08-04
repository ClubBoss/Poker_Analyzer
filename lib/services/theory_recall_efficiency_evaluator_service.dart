import 'recall_boost_interaction_logger.dart';
import 'recall_success_logger_service.dart';

/// Calculates how effective theory snippets are at restoring decayed tags.
class TheoryRecallEfficiencyEvaluatorService {
  final RecallBoostInteractionLogger viewLogger;
  final RecallSuccessLoggerService successLogger;

  const TheoryRecallEfficiencyEvaluatorService({
    RecallBoostInteractionLogger? viewLogger,
    RecallSuccessLoggerService? successLogger,
  })  : viewLogger = viewLogger ?? RecallBoostInteractionLogger.instance,
        successLogger = successLogger ?? RecallSuccessLoggerService.instance;

  /// Returns efficiency scores per tag (successful recalls / theory views).
  Future<Map<String, double>> getEfficiencyScoresByTag() async {
    final views = await viewLogger.getLogs();
    final successes = await successLogger.getSuccesses();

    final viewCounts = <String, int>{};
    for (final v in views) {
      if (v.durationMs < 1000) continue; // require at least 1s exposure
      final tag = v.tag.trim().toLowerCase();
      if (tag.isEmpty) continue;
      viewCounts[tag] = (viewCounts[tag] ?? 0) + 1;
    }

    final successCounts = <String, int>{};
    for (final s in successes) {
      final tag = s.tag.trim().toLowerCase();
      if (tag.isEmpty) continue;
      successCounts[tag] = (successCounts[tag] ?? 0) + 1;
    }

    final scores = <String, double>{};
    viewCounts.forEach((tag, totalViews) {
      if (totalViews == 0) return;
      final success = successCounts[tag] ?? 0;
      scores[tag] = success / totalViews;
    });

    return scores;
  }
}

