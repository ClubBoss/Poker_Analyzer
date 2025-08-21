import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_booster_effectiveness_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('trackBoosterEffect stores entry', () async {
    await TheoryBoosterEffectivenessService.instance.trackBoosterEffect(
      'b1',
      'standard',
      0.05,
      10,
    );
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('booster_effectiveness_logs')!;
    final list = jsonDecode(raw) as List;
    expect(list.length, 1);
    final data = list.first as Map<String, dynamic>;
    expect(data['id'], 'b1');
    expect(data['type'], 'standard');
    expect(data['deltaEV'], 0.05);
    expect(data['spotsTracked'], 10);
  });

  test('getImpactStats filters by id', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'booster_effectiveness_logs': jsonEncode([
        {
          'id': 'a',
          'type': 'mini',
          'deltaEV': 0.1,
          'spotsTracked': 5,
          'timestamp': now.toIso8601String(),
        },
        {
          'id': 'b',
          'type': 'standard',
          'deltaEV': -0.02,
          'spotsTracked': 8,
          'timestamp': now.toIso8601String(),
        },
      ]),
    });
    final list = await TheoryBoosterEffectivenessService.instance
        .getImpactStats('b');
    expect(list.length, 1);
    expect(list.first.id, 'b');
    expect(list.first.deltaEV, -0.02);
  });
}
