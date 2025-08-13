import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('CLI does not warn when only --weightsPreset is set', () async {
    final tmp = Directory.systemTemp.createTempSync('l3_cli_no_warn_');
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
        'default',
      ]);
      expect(res.exitCode, 0, reason: 'stderr: ${res.stderr}');
      expect(res.stderr.toString(),
          isNot(contains('both --weights and --weightsPreset')));
      expect(File(outPath).existsSync(), isTrue);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });
}
