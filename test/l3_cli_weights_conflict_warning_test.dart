import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('CLI warns when both --weights and --weightsPreset are set', () async {
    final res = await Process.run('dart', [
      'run',
      'tool/l3/pack_run_cli.dart',
      '--dir',
      'build/tmp/l3/111', // неважно: до чтения флагов не дойдёт
      '--out',
      'build/reports/l3_packrun_warn.json',
      '--weights',
      '{"spr_low":0.1}', // минимальный валидный JSON
      '--weightsPreset',
      'aggro',
    ]);
    // CLI должен не падать…
    expect(res.exitCode, 0, reason: res.stderr.toString());
    // …и печатать предупреждение в stderr
    expect(
      res.stderr.toString(),
      contains('both --weights and --weightsPreset'),
    );
  });
}
