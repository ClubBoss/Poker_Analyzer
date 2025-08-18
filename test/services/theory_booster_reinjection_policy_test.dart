import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_booster_reinjection_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shouldReinject returns false for low impact booster', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'booster_effectiveness_logs': jsonEncode([
        {
          'id': 'b1',
          'type': 'standard',
          'deltaEV': 0.005,
          'spotsTracked': 3,
          'timestamp': now.toIso8601String(),
        },
      ]),
    });
    final policy = TheoryBoosterReinjectionPolicy();
    expect(await policy.shouldReinject('b1'), false);
  });

  test('shouldReinject returns true when impact is high', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'booster_effectiveness_logs': jsonEncode([
        {
          'id': 'b2',
          'type': 'standard',
          'deltaEV': 0.1,
          'spotsTracked': 10,
          'timestamp': now.toIso8601String(),
        },
      ]),
    });
    final policy = TheoryBoosterReinjectionPolicy();
    expect(await policy.shouldReinject('b2'), true);
  });

  test('caches low impact booster ids', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'booster_effectiveness_logs': jsonEncode([
        {
          'id': 'b3',
          'type': 'standard',
          'deltaEV': 0.0,
          'spotsTracked': 4,
          'timestamp': now.toIso8601String(),
        },
      ]),
    });
    final policy = TheoryBoosterReinjectionPolicy();
    expect(await policy.shouldReinject('b3'), false);

    SharedPreferences.setMockInitialValues({
      'booster_effectiveness_logs': jsonEncode([
        {
          'id': 'b3',
          'type': 'standard',
          'deltaEV': 0.2,
          'spotsTracked': 10,
          'timestamp': now.toIso8601String(),
        },
      ]),
    });
    // Should still be false because id is cached
    expect(await policy.shouldReinject('b3'), false);
  });
}
