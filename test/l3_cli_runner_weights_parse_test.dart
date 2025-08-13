import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/l3_cli_runner.dart';

void main() {
  test(
    'extractTargetMix parses inline json with map tolerance and min total',
    () {
      final res = extractTargetMix(
        '{"targetMix":{"two_tone":0.3,"broadway":0.25},"mixTolerance":{"two_tone":0.04},"mixMinTotal":75}',
      );
      expect(res, isNotNull);
      expect(res!.mix.containsKey('twoTone'), isTrue);
      expect(res.mix.containsKey('broadwayHeavy'), isTrue);
      expect(res.defaultTol, 0.10);
      expect(res.byKeyTol['twoTone'], 0.04);
      expect(res.minTotal, 75);
    },
  );

  test(
    'extractTargetMix parses file path with map tolerance and min total',
    () {
      final file = File('${Directory.systemTemp.path}/weights.json');
      file.writeAsStringSync(
        '{"targetMix":{"two_tone":0.3},"mixTolerance":{"two_tone":0.04},"mixMinTotal":75}',
      );
      final res = extractTargetMix(file.path);
      expect(res, isNotNull);
      expect(res!.mix['twoTone'], 0.3);
      expect(res.defaultTol, 0.10);
      expect(res.byKeyTol['twoTone'], 0.04);
      expect(res.minTotal, 75);
      file.deleteSync();
    },
  );
}

