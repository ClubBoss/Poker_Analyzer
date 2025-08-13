import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/tag_decay_forecast.dart';
import 'package:poker_analyzer/services/decay_forecast_alert_service.dart';
import 'package:poker_analyzer/services/decay_forecast_engine.dart';

class _FakeEngine extends DecayForecastEngine {
  final List<TagDecayForecast> forecasts;
  const _FakeEngine(this.forecasts);

  @override
  Future<List<TagDecayForecast>> forecast(List<String> tags,
      {int horizonDays = 30}) async {
    return forecasts;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects upcoming critical tags', () async {
    final service = DecayForecastAlertService(
      engine: _FakeEngine([
        const TagDecayForecast(
            tag: 'a', current: 50, in7days: 70, in14days: 80, in30days: 90),
        const TagDecayForecast(
            tag: 'b', current: 40, in7days: 50, in14days: 65, in30days: 70),
        const TagDecayForecast(
            tag: 'c', current: 10, in7days: 20, in14days: 30, in30days: 40),
      ]),
    );

    final alerts = await service.getUpcomingCriticalTags(['a', 'b', 'c']);
    expect(alerts.length, 2);

    final a = alerts.firstWhere((e) => e.tag == 'a');
    expect(a.daysToCritical, 7);
    expect(a.projectedDecay, 70);

    final b = alerts.firstWhere((e) => e.tag == 'b');
    expect(b.daysToCritical, 14);
    expect(b.projectedDecay, 65);
  });
}
