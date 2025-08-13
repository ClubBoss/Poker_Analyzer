import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/l3_cli_runner.dart';

void main() {
  test(
    'extractTargetMix parses inline json',
    () {
      final res = extractTargetMix('{"targetMix":{"rainbow":0.2}}');
      expect(res, isNotNull);
      expect(res!.mix['rainbow'], 0.2);
      expect(res.tolerance, 0.10);
    },
  );

  test(
    'extractTargetMix parses file path with tolerance',
    () {
      final file = File('${Directory.systemTemp.path}/weights.json');
      file.writeAsStringSync(
        '{"targetMix":{"monotone":0.3},"mixTolerance":0.05}',
      );
      final res = extractTargetMix(file.path);
      expect(res, isNotNull);
      expect(res!.mix['monotone'], 0.3);
      expect(res.tolerance, 0.05);
      file.deleteSync();
    },
  );

  test(
    'extractTargetMix normalizes keys',
    () {
      final res = extractTargetMix(
        '{"targetMix":{"two_tone":0.3,"broadway":0.25}}',
      );
      expect(res, isNotNull);
      expect(res!.mix.containsKey('twoTone'), isTrue);
      expect(res.mix.containsKey('broadwayHeavy'), isTrue);
    },
  );
}
