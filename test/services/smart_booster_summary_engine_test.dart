import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_booster_summary_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('summarize aggregates logs', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'booster_effectiveness_logs': jsonEncode([
        {
          'id': 'b1',
          'type': 'standard',
          'deltaEV': 0.05,
          'spotsTracked': 10,
          'timestamp': now.toIso8601String(),
        },
        {
          'id': 'b1',
          'type': 'standard',
          'deltaEV': -0.01,
          'spotsTracked': 5,
          'timestamp': now.toIso8601String(),
        },
      ]),
    });
    final engine = SmartBoosterSummaryEngine();
    final summary = await engine.summarize('b1');
    expect(summary.injections, 2);
    expect(summary.totalSpots, 15);
    expect(summary.avgDeltaEV, closeTo(0.02, 0.0001));
    expect(summary.isEffective, true);
  });

  test('summarizeAll sorts by effectiveness', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'booster_effectiveness_logs': jsonEncode([
        {
          'id': 'b1',
          'type': 'standard',
          'deltaEV': 0.02,
          'spotsTracked': 4,
          'timestamp': now.toIso8601String(),
        },
        {
          'id': 'b2',
          'type': 'standard',
          'deltaEV': -0.01,
          'spotsTracked': 6,
          'timestamp': now.toIso8601String(),
        },
        {
          'id': 'b2',
          'type': 'standard',
          'deltaEV': 0.01,
          'spotsTracked': 6,
          'timestamp': now.toIso8601String(),
        },
      ]),
    });
    final engine = SmartBoosterSummaryEngine();
    final list = await engine.summarizeAll([
      'b1',
      'b2',
    ], sortByEffectiveness: true);
    expect(list.first.id, 'b1');
    expect(list.last.id, 'b2');
  });
}
