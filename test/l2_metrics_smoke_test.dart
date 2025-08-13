import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('l2 metrics smoke', () async {
    final result = await Process.run('dart', [
      'run',
      'tool/metrics/l2_metrics_report.dart',
      '--packs',
      'assets/packs/l2',
      '--snippets',
      'assets/theory/l2/snippets.yaml',
      '--out',
      'build/tmp/l2_report.md',
    ]);
    expect(result.exitCode, 0);
    final output = result.stdout.toString();
    expect(output, contains('coverage'));
    expect(output, contains('open-fold'));
    expect(output, contains('3bet-push'));
    expect(output, contains('limped'));
  });
}
