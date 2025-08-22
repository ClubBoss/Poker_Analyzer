import 'tag_decay_forecast_service.dart';

class TagReviewAdvice {
  final String tag;
  final double decay;
  final int recommendedDaysUntilReview;

  TagReviewAdvice({
    required this.tag,
    required this.decay,
    required this.recommendedDaysUntilReview,
  });
}

class DecayReviewFrequencyAdvisorService {
  final TagDecayForecastService forecastService;

  DecayReviewFrequencyAdvisorService({
    this.forecastService = const TagDecayForecastService(),
  });

  Future<List<TagReviewAdvice>> getAdvice() async {
    final forecasts = await forecastService.getAllForecasts();
    final result = <TagReviewAdvice>[];
    for (final entry in forecasts.entries) {
      final decay = entry.value;
      if (decay <= 0.5) continue;
      result.add(
        TagReviewAdvice(
          tag: entry.key,
          decay: decay,
          recommendedDaysUntilReview: _suggestDays(decay),
        ),
      );
    }
    result.sort((a, b) => b.decay.compareTo(a.decay));
    return result;
  }

  int _suggestDays(double decay) {
    if (decay >= 0.9) return 0;
    if (decay >= 0.7) return 1;
    return 3;
  }
}
