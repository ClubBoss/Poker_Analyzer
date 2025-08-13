import 'package:test/test.dart';
import 'package:poker_analyzer/services/l3_cli_runner.dart';

void main() {
  test('extractTargetMix parses inline per-key map with mixMinTotal', () {
    final res = extractTargetMix(
      '{"targetMix":{"two_tone":0.3,"broadway":0.25},"mixTolerance":{"two_tone":0.04},"mixMinTotal":75}',
    );
    expect(res, isNotNull);
    expect(res!.mix.containsKey('twoTone'), isTrue);
    expect(res.mix.containsKey('broadwayHeavy'), isTrue);
    expect(res.byKeyTol['twoTone'], 0.04);
    expect(res.minTotal, 75);
  });

  test('extractTargetMix parses inline numeric mixTolerance', () {
    final res = extractTargetMix(
      '{"targetMix":{"two_tone":0.3},"mixTolerance":0.10,"toleranceByKey":{"two_tone":0.04},"minTotal":75}',
    );
    expect(res, isNotNull);
    expect(res!.mix['twoTone'], 0.3);
    expect(res.defaultTol, 0.10);
    expect(res.byKeyTol['twoTone'], 0.04);
    expect(res.minTotal, 75);
  });

  test(
    'extractTargetMix parses file path with per-key map and minTotalSamples',
    () {
      final res = extractTargetMix(
        'test/fixtures/l3/weights/per_key_min_total_samples.json',
      );
      expect(res, isNotNull);
      expect(res!.mix['twoTone'], 0.3);
      expect(res.byKeyTol['twoTone'], 0.04);
      expect(res.minTotal, 75);
    },
  );
}
