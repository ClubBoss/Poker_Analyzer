import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('pack run summary contains preset and SPR stats', () async {
    final outDir = 'build/tmp/l3_cli/222';
    final gen = await Process.run('dart', [
      'run',
      'tool/autogen/l3_board_generator.dart',
      '--preset',
      'paired',
      '--seed',
      '222',
      '--maxAttemptsPerSpot',
      '5000',
      '--timeoutSec',
      '90',
      '--out',
      outDir,
    ]);
    expect(gen.exitCode, 0, reason: gen.stderr.toString());

    final reportFile = File('build/reports/l3_packrun_preset.json');
    final run = await Process.run('dart', [
      'run',
      'tool/l3/pack_run_cli.dart',
      '--dir',
      outDir,
      '--out',
      reportFile.path,
    ]);
    expect(run.exitCode, 0, reason: run.stderr.toString());

    final report =
        json.decode(reportFile.readAsStringSync()) as Map<String, dynamic>;
    final summary = report['summary'] as Map<String, dynamic>;

    final presetCounts = summary['presetCounts'] as Map<String, dynamic>?;
    expect(presetCounts, isNotNull);
    final presetKeys = presetCounts!.keys.where(
      (k) => k == 'paired' || k == 'unpaired' || k == 'ace-high',
    );
    expect(presetKeys, isNotEmpty);

    final sprHistogram = summary['sprHistogram'] as Map<String, dynamic>?;
    expect(sprHistogram, isNotNull);
    expect(sprHistogram!.keys, containsAll(['spr_low', 'spr_mid', 'spr_high']));
  });
}
