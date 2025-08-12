import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('smoke generator produces spots', () async {
    final result = await Process.run('dart', [
      'run',
      'tool/validators/smoke_gen.dart',
    ]);
    if (result.exitCode != 0) {
      fail(
        'smoke_gen failed\nstdout: ${result.stdout}\nstderr: ${result.stderr}',
      );
    }
  });
}
