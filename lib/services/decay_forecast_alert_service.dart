import '../models/decay_forecast_alert.dart';
import '../services/decay_forecast_engine.dart';

/// Scans decay forecasts and returns upcoming critical tags.
class DecayForecastAlertService {
  final DecayForecastEngine engine;
  final double threshold;

  DecayForecastAlertService({DecayForecastEngine? engine, this.threshold = 60})
    : engine = engine ?? const DecayForecastEngine();

  /// Returns tags predicted to exceed [threshold] decay soon.
  Future<List<DecayForecastAlert>> getUpcomingCriticalTags(
    List<String> tags,
  ) async {
    final forecasts = await engine.forecast(tags);
    final result = <DecayForecastAlert>[];
    for (final f in forecasts) {
      if (f.in7days > threshold) {
        result.add(
          DecayForecastAlert(
            tag: f.tag,
            daysToCritical: 7,
            projectedDecay: f.in7days,
          ),
        );
      } else if (f.in14days > threshold) {
        result.add(
          DecayForecastAlert(
            tag: f.tag,
            daysToCritical: 14,
            projectedDecay: f.in14days,
          ),
        );
      }
    }
    return result;
  }
}
