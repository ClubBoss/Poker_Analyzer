import '../models/decay_retention_summary.dart';
import 'tag_decay_forecast_service.dart';

/// Aggregates decay metrics across all tracked tags.
class DecayRetentionSummaryService {
  final TagDecayForecastService forecastService;

  DecayRetentionSummaryService({TagDecayForecastService? forecastService})
      : forecastService = forecastService ?? TagDecayForecastService();

  /// Computes current decay summary for all tags.
  Future<DecayRetentionSummary> getSummary() async {
    final forecasts = await forecastService.getAllForecasts();
    final total = forecasts.length;
    if (total == 0) {
      return const DecayRetentionSummary(
        totalTags: 0,
        decayedTags: 0,
        averageDecay: 0,
        topForgotten: [],
      );
    }

    final values = forecasts.values.toList();
    final decayed = values.where((d) => d > 0.7).length;
    final avg = values.reduce((a, b) => a + b) / total;
    final top = forecasts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final forgotten = [for (final e in top.take(3)) e.key];

    return DecayRetentionSummary(
      totalTags: total,
      decayedTags: decayed,
      averageDecay: avg,
      topForgotten: forgotten,
    );
  }
}
