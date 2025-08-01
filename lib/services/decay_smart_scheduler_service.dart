import '../models/daily_review_plan.dart';
import 'tag_decay_forecast_service.dart';
import 'decay_review_frequency_advisor_service.dart';

/// Generates a prioritized list of tags to review each day.
class DecaySmartSchedulerService {
  final TagDecayForecastService forecastService;
  final DecayReviewFrequencyAdvisorService advisor;

  const DecaySmartSchedulerService({
    TagDecayForecastService? forecastService,
    DecayReviewFrequencyAdvisorService? advisor,
  })  : forecastService = forecastService ?? const TagDecayForecastService(),
        advisor = advisor ?? const DecayReviewFrequencyAdvisorService();

  /// Builds today\'s review plan using decay analytics.
  Future<DailyReviewPlan> generateTodayPlan() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final forecasts = await forecastService.getAllForecasts();
    final critical = forecasts.entries
        .where((e) => e.value > 0.8)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final criticalTags = [for (final e in critical) e.key];

    final advice = await advisor.getAdvice();
    final soon = advice
        .where((a) => a.recommendedDaysUntilReview <= 1)
        .map((a) => a.tag)
        .toList();

    final tags = <String>[];
    for (final t in criticalTags) {
      if (tags.length >= 10) break;
      tags.add(t);
    }
    for (final t in soon) {
      if (tags.length >= 10) break;
      if (!tags.contains(t)) {
        tags.add(t);
      }
    }

    return DailyReviewPlan(date: today, tags: tags);
  }
}
