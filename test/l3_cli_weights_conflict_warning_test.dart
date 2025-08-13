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
      // CLI должен не падать…
      expect(res.exitCode, 0, reason: res.stderr.toString());
      // …и печатать предупреждение в stderr
      expect(
        res.stderr.toString(),
        contains('both --weights and --weightsPreset'),
      );
      // и сформировать JSON-репорт (пусть и пустой)
      expect(File(outPath).existsSync(), isTrue);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });
}
