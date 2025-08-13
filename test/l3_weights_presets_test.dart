import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('weight presets influence jam rate', () async {
    const outDir = 'build/tmp/l3/222';
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

    Future<Map<String, dynamic>> runPack(String out, [String? weights]) async {
      final args = [
        'run',
        'tool/l3/pack_run_cli.dart',
        '--dir',
        outDir,
        '--out',
        out,
      ];
      if (weights != null) {
        args.addAll(['--weights', weights]);
      }
      final res = await Process.run('dart', args);
      expect(res.exitCode, 0, reason: res.stderr.toString());
      return json.decode(File(out).readAsStringSync()) as Map<String, dynamic>;
    }

    final defaultReport = await runPack(
      'build/reports/l3_packrun_default.json',
    );
    final aggroReport = await runPack(
      'build/reports/l3_packrun_aggro.json',
      'tool/config/weights/aggro.json',
    );
    final nittyReport = await runPack(
      'build/reports/l3_packrun_nitty.json',
      'tool/config/weights/nitty.json',
    );

    double jamRate(Map<String, dynamic> report) {
      final summary = report['summary'] as Map<String, dynamic>;
      return (summary['avgJamRate'] as num).toDouble();
    }

    final defaultJam = jamRate(defaultReport);
    final aggroJam = jamRate(aggroReport);
    final nittyJam = jamRate(nittyReport);

    expect(aggroJam, greaterThan(defaultJam));
    expect(defaultJam, greaterThan(nittyJam));
  });
}
