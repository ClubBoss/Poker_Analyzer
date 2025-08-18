import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/booster_adaptation_tuner.dart';
import 'package:poker_analyzer/services/booster_effectiveness_analyzer.dart';

class _FakeAnalyzer extends BoosterEffectivenessAnalyzer {
  final Map<String, double> map;
  const _FakeAnalyzer(this.map);

  @override
  Future<Map<String, double>> computeEffectiveness({DateTime? now}) async {
    return map;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BoosterAdaptationTuner.instance.resetForTest();
  });

  test('computeAdaptations classifies scores', () async {
    final tuner = BoosterAdaptationTuner(
      analyzer: _FakeAnalyzer({'a': 0.1, 'b': 0.3, 'c': 0.8}),
    );
    final result = await tuner.computeAdaptations();

    expect(result['a'], BoosterAdaptation.reduce);
    expect(result['b'], BoosterAdaptation.keep);
    expect(result['c'], BoosterAdaptation.increase);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('booster_adaptations');
    final map = jsonDecode(raw!) as Map;
    expect(map['a'], 'reduce');
    expect(map['b'], 'keep');
    expect(map['c'], 'increase');
  });

  test('loadAdaptations reads saved values', () async {
    final tuner = BoosterAdaptationTuner(analyzer: _FakeAnalyzer({'a': 0.6}));
    await tuner.computeAdaptations();

    tuner.resetForTest();
    final loaded = await tuner.loadAdaptations();
    expect(loaded['a'], BoosterAdaptation.increase);
  });
}
