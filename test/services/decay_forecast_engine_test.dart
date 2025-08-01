import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/decay_forecast_engine.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';

class _FakeRetention extends DecayTagRetentionTrackerService {
  final Map<String, double> scores;
  const _FakeRetention(this.scores);
  @override
  Future<double> getDecayScore(String tag, {DateTime? now}) async {
    return scores[tag] ?? 0.0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('forecast adds days to current decay', () async {
    final engine = DecayForecastEngine(
      retention: const _FakeRetention({'a': 10, 'b': 20}),
    );
    final list = await engine.forecast(['a', 'b']);
    final a = list.firstWhere((e) => e.tag == 'a');
    expect(a.current, 10);
    expect(a.in7days, 17);
    expect(a.in14days, 24);
    expect(a.in30days, 40);
  });
}
