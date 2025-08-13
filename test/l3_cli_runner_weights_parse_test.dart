import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/l3_cli_runner.dart';

void main() {
  test('extractTargetMix parses inline json', () {
    final mix = extractTargetMix('{"targetMix":{"rainbow":0.2}}');
    expect(mix, isNotNull);
    expect(mix!['rainbow'], 0.2);
  });

  test('extractTargetMix parses file path', () {
    final file = File('${Directory.systemTemp.path}/weights.json');
    file.writeAsStringSync('{"targetMix":{"monotone":0.3}}');
    final mix = extractTargetMix(file.path);
    expect(mix, isNotNull);
    expect(mix!['monotone'], 0.3);
    file.deleteSync();
  });
}
