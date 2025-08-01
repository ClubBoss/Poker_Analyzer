import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/services/decay_review_frequency_advisor_service.dart';
import 'package:poker_analyzer/services/tag_decay_forecast_service.dart';

class _FakeForecast extends TagDecayForecastService {
  final Map<String, double> map;
  const _FakeForecast(this.map);
  @override
  Future<Map<String, double>> getAllForecasts() async => map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns advice sorted by decay', () async {
    const service = DecayReviewFrequencyAdvisorService(
      forecastService: _FakeForecast({'a': 0.6, 'b': 0.8, 'c': 0.4}),
    );
    final list = await service.getAdvice();
    expect(list.length, 2);
    expect(list.first.tag, 'b');
    expect(list.first.recommendedDaysUntilReview, 1);
    expect(list[1].tag, 'a');
    expect(list[1].recommendedDaysUntilReview, 3);
  });
}
