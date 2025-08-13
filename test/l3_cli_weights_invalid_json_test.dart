import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('CLI fails with non-zero exit on invalid JSON in --weights', () async {
    final tmp = Directory.systemTemp.createTempSync('l3_cli_bad_json_');
    try {
      final res = await Process.run('dart', [
        'run',
        'tool/l3/pack_run_cli.dart',
        '--dir',
        tmp.path,
        '--out',
        '${tmp.path}/out.json',
        '--weights',
        '{bad-json',
      ]);
      expect(res.exitCode, isNot(0));
      expect(
        res.stderr.toString(),
        anyOf(contains('FormatException'), contains('Unexpected character')),
      );
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });
}
