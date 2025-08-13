import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('theory snippet coverage >= 0.90', () async {
    final result = await Process.run('dart', [
      'run',
      'tool/validators/theory_snippet_coverage.dart',
      '--packs', 'assets/packs/l2',
      '--snippets', 'assets/theory/l2/snippets.yaml',
      '--min', '0.90',
    ]);
    if (result.exitCode != 0) {
      fail('validator failed: \n${result.stdout}\n${result.stderr}');
    }
  });
}
