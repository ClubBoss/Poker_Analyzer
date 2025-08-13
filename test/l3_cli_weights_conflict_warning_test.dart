import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('CLI warns when both --weights and --weightsPreset are set', () async {
    final tmp = Directory.systemTemp.createTempSync('l3_cli_warn_');
    try {
      final outPath = '${tmp.path}/out.json';
      final res = await Process.run('dart', [
        'run',
        'tool/l3/pack_run_cli.dart',
        '--dir',
        tmp.path, // герметично: пустая директория существует
        '--out',
        outPath,
        '--weights',
        '{"spr_low":0.1}', // минимальный валидный JSON
        '--weightsPreset',
        'aggro',
      ]);
      expect(res.exitCode, 0, reason: res.stderr.toString());
      expect(res.stderr.toString(),
          contains('both --weights and --weightsPreset'));
      expect(File(outPath).existsSync(), isTrue);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });

  test('CLI does not warn when only --weights is set', () async {
    final tmp = Directory.systemTemp.createTempSync('l3_cli_weights_only_');
    try {
      final outPath = '${tmp.path}/out.json';
      final res = await Process.run('dart', [
        'run',
        'tool/l3/pack_run_cli.dart',
        '--dir',
        tmp.path,
        '--out',
        outPath,
        '--weights',
        '{"spr_low":0.1}',
      ]);
      expect(res.exitCode, 0, reason: res.stderr.toString());
      expect(res.stderr.toString(),
          isNot(contains('both --weights and --weightsPreset')));
      expect(File(outPath).existsSync(), isTrue);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });

  test('CLI does not warn when only --weightsPreset is set', () async {
    final tmp = Directory.systemTemp.createTempSync('l3_cli_preset_only_');
    try {
      final outPath = '${tmp.path}/out.json';
      final res = await Process.run('dart', [
        'run',
        'tool/l3/pack_run_cli.dart',
        '--dir',
        tmp.path,
        '--out',
        outPath,
        '--weightsPreset',
        'aggro',
      ]);
      expect(res.exitCode, 0, reason: res.stderr.toString());
      expect(res.stderr.toString(),
          isNot(contains('both --weights and --weightsPreset')));
      expect(File(outPath).existsSync(), isTrue);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });
}
