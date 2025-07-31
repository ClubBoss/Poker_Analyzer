import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/services/decay_heatmap_model_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate maps decay scores to heatmap entries', () {
    final generator = DecayHeatmapModelGenerator();
    final result = generator.generate({'a': 10, 'b': 40, 'c': 70});

    expect(result.length, 3);
    final a = result.firstWhere((e) => e.tag == 'a');
    final b = result.firstWhere((e) => e.tag == 'b');
    final c = result.firstWhere((e) => e.tag == 'c');

    expect(a.decay, 10);
    expect(a.level, DecayLevel.ok);
    expect(b.level, DecayLevel.warning);
    expect(c.level, DecayLevel.critical);
  });

  test('generate handles empty input', () {
    final generator = DecayHeatmapModelGenerator();
    final result = generator.generate({});
    expect(result, isEmpty);
  });
}
