import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('compile path cli', () async {
    final packs = await Directory.systemTemp.createTemp('compile_path_packs');
    try {
      // create sample pack files
      for (final stage in ['bb10_UTG', 'bb10_CO', 'bb10_BTN']) {
        await File(p.join(packs.path, '${stage}_main.yaml')).writeAsString('');
      }
      final txtFile = File(p.join(packs.path, 'bb10.txt'));
      await txtFile.writeAsString('bb10_UTG:A\nbb10_CO:A\nbb10_BTN:A\n');

      final res = await Process.run('dart', [
        'run',
        'tool/compile_path.dart',
        txtFile.path,
        packs.path,
      ]);
      expect(
        res.exitCode,
        0,
        reason: 'stdout: ${res.stdout}\nstderr: ${res.stderr}',
      );
      final outFile = File('compiled/path.yaml');
      expect(outFile.existsSync(), isTrue);
      final content = outFile.readAsStringSync();
      expect(content.trim().isNotEmpty, isTrue);
    } finally {
      await Directory('compiled').delete(recursive: true);
      await packs.delete(recursive: true);
    }
  });
}
