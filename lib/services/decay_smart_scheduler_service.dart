import '../models/daily_review_plan.dart';
import '../models/tag_review_task.dart';
import 'booster_adaptation_tuner.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'review_streak_evaluator_service.dart';

/// Generates a prioritized list of tags to review each day.
class DecaySmartSchedulerService {
  final DecayTagRetentionTrackerService retention;
  final BoosterAdaptationTuner tuner;
  final ReviewStreakEvaluatorService streak;

  DecaySmartSchedulerService({
    this.retention = const DecayTagRetentionTrackerService(),
    BoosterAdaptationTuner? tuner,
    this.streak = const ReviewStreakEvaluatorService(),
  }) : tuner = tuner ?? BoosterAdaptationTuner();

  /// Weight multiplier for decay score when computing priority.
  static const double weightDecay = 1.5;

  /// Generates prioritized review tasks combining decay analytics, booster
  /// adaptations and recency of previous reviews.
  Future<List<TagReviewTask>> generateSchedule() async {
    final decayScores = await retention.getAllDecayScores();
    final adaptations = await tuner.loadAdaptations();
    final tagStats = await streak.getTagStats();
    final now = DateTime.now();

    final tags = <String>{
      ...decayScores.keys,
      ...adaptations.keys,
      ...tagStats.keys,
    }..removeWhere((t) => t.isEmpty);

    final tasks = <TagReviewTask>[];
    for (final tag in tags) {
      final decay = decayScores[tag] ?? 0.0;
      final adapt = adaptations[tag];
      double adaptWeight = 0.0;
      if (adapt == BoosterAdaptation.increase) {
        adaptWeight = 1.0;
      } else if (adapt == BoosterAdaptation.reduce) {
        adaptWeight = -1.0;
      }

      double penalty = 0.0;
      final stat = tagStats[tag];
      if (stat != null) {
        final diff = now.difference(stat.lastInteraction);
        if (diff <= const Duration(days: 1)) {
          penalty = -1.0;
        } else if (diff <= const Duration(days: 3)) {
          penalty = -0.5;
        }
      }

      final score = decay * weightDecay + adaptWeight + penalty;
      tasks.add(TagReviewTask(tag: tag, priority: score));
    }

    tasks.sort((a, b) => b.priority.compareTo(a.priority));
    return tasks;
  }

  /// Builds today's review plan taking the top [maxTags] tasks from the
  /// generated schedule.
  Future<DailyReviewPlan> generateTodayPlan({int maxTags = 10}) async {
    final tasks = await generateSchedule();
    final tags = [for (final t in tasks.take(maxTags)) t.tag];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DailyReviewPlan(date: today, tags: tags);
  }
}
