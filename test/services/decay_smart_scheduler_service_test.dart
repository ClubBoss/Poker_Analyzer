import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/services/decay_smart_scheduler_service.dart';
import 'package:poker_analyzer/services/tag_decay_forecast_service.dart';
import 'package:poker_analyzer/services/decay_review_frequency_advisor_service.dart';
import 'package:poker_analyzer/models/daily_review_plan.dart';

class _FakeForecast extends TagDecayForecastService {
  final Map<String, double> map;
  const _FakeForecast(this.map);
  @override
  Future<Map<String, double>> getAllForecasts() async => map;
}

class _FakeAdvisor extends DecayReviewFrequencyAdvisorService {
  final List<TagReviewAdvice> list;
  const _FakeAdvisor(this.list);
  @override
  Future<List<TagReviewAdvice>> getAdvice() async => list;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('combines critical and soon advice', () async {
    const service = DecaySmartSchedulerService(
      forecastService: _FakeForecast({'a': 0.9, 'b': 0.85, 'c': 0.75}),
      advisor: _FakeAdvisor([
        TagReviewAdvice(tag: 'c', decay: 0.75, recommendedDaysUntilReview: 0),
        TagReviewAdvice(tag: 'd', decay: 0.65, recommendedDaysUntilReview: 1),
        TagReviewAdvice(tag: 'a', decay: 0.9, recommendedDaysUntilReview: 0),
      ]),
    );

    final DailyReviewPlan plan = await service.generateTodayPlan();
    expect(plan.tags, ['a', 'b', 'c', 'd']);
  });

  test('limits to 10 tags', () async {
    final map = <String, double>{};
    for (var i = 0; i < 12; i++) {
      map['t\\$i'] = 0.9 - i * 0.01;
    }
    const advisor = DecayReviewFrequencyAdvisorService();
    final service = DecaySmartSchedulerService(
      forecastService: _FakeForecast(map),
      advisor: advisor,
    );
    final plan = await service.generateTodayPlan();
    expect(plan.tags.length, 10);
  });
}
