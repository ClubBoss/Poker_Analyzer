import '../models/decay_analytics_export.dart';
import 'booster_adaptation_tuner.dart';
import 'decay_review_frequency_advisor_service.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'review_streak_evaluator_service.dart';

class DecayAnalyticsExporterService {
  final DecayTagRetentionTrackerService retention;
  final BoosterAdaptationTuner tuner;
  final ReviewStreakEvaluatorService streak;
  final DecayReviewFrequencyAdvisorService advisor;

  DecayAnalyticsExporterService({
    this.retention = const DecayTagRetentionTrackerService(),
    BoosterAdaptationTuner? tuner,
    this.streak = const ReviewStreakEvaluatorService(),
    this.advisor = const DecayReviewFrequencyAdvisorService(),
  }) : tuner = tuner ?? BoosterAdaptationTuner();

  Future<List<DecayAnalyticsExport>> exportAnalytics() async {
    final decayScores = await retention.getAllDecayScores();
    final adaptations = await tuner.loadAdaptations();
    final tagStats = await streak.getTagStats();
    final adviceList = await advisor.getAdvice();
    final adviceMap = {for (final a in adviceList) a.tag: a};

    final tags = <String>{
      ...decayScores.keys,
      ...adaptations.keys,
      ...tagStats.keys,
      ...adviceMap.keys,
    }..removeWhere((t) => t.isEmpty);

    final exports = <DecayAnalyticsExport>[];
    for (final tag in tags) {
      exports.add(
        DecayAnalyticsExport(
          tag: tag,
          decay: decayScores[tag] ?? 0.0,
          adaptation: adaptations[tag] ?? BoosterAdaptation.keep,
          lastInteraction: tagStats[tag]?.lastInteraction,
          recommendedDaysUntilReview:
              adviceMap[tag]?.recommendedDaysUntilReview ?? 0,
        ),
      );
    }

    exports.sort((a, b) => b.decay.compareTo(a.decay));
    return exports;
  }
}
