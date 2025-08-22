import '../models/tag_decay_forecast.dart';
import 'decay_tag_retention_tracker_service.dart';

/// Predicts future decay levels per tag assuming no further reviews.
class DecayForecastEngine {
  final DecayTagRetentionTrackerService retention;

  DecayForecastEngine({
    this.retention = const DecayTagRetentionTrackerService(),
  });

  /// Returns forecasted decay scores for [tags].
  /// Forecast horizon defaults to 30 days but 7/14/30 day values are always returned.
  Future<List<TagDecayForecast>> forecast(
    List<String> tags, {
    int horizonDays = 30,
  }) async {
    final result = <TagDecayForecast>[];
    for (final raw in tags) {
      final tag = raw.trim().toLowerCase();
      if (tag.isEmpty) continue;
      final current = await retention.getDecayScore(tag);
      result.add(
        TagDecayForecast(
          tag: tag,
          current: current,
          in7days: current + 7,
          in14days: current + 14,
          in30days: current + 30,
        ),
      );
    }
    return result;
  }
}
