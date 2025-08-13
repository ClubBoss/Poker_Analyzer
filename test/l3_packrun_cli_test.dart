import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('pack run cli smoke', () async {
    final outDir = 'build/tmp/l3_cli/111';
    final gen = await Process.run('dart', [
      'run',
      'tool/autogen/l3_board_generator.dart',
      '--preset',
      'paired',
      '--seed',
      '111',
      '--out',
      outDir,
    ]);
    expect(gen.exitCode, 0, reason: gen.stderr.toString());
    final reportFile = File('build/reports/l3_packrun_test.json');
    final run = await Process.run('dart', [
      'run',
      'tool/l3/pack_run_cli.dart',
      '--dir',
      outDir,
      '--out',
      reportFile.path,
    ]);
    expect(run.exitCode, 0, reason: run.stderr.toString());
    final report = json.decode(reportFile.readAsStringSync()) as Map<String, dynamic>;
    final spots = report['spots'] as List<dynamic>;
    expect(spots, isNotEmpty);
    for (final spot in spots) {
      expect(spot['decision'], isIn(['jam', 'fold']));
    }
  });
}
