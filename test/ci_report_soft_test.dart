import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('ci_report soft mode exits 0 when no report', () async {
    final tempDir = await Directory.systemTemp.createTemp();
    final missing = p.join(tempDir.path, 'missing.json');
    final result = await Process.run(
      'dart',
      ['run', 'bin/ci_report.dart', '--mode=soft', '--report', missing],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: 'soft mode should not fail');
  });
}
