import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('cli --help prints usage', () async {
    final dart = Platform.resolvedExecutable;
    final result = await Process.run(dart, [
      'run',
      'bin/ev_rank_jam_fold_deltas.dart',
      '--help',
    ]);
    expect(result.exitCode, 0);
    final out = (result.stdout ?? '').toString();
    expect(out, contains('Usage:'));
    expect(out, contains('--format <json|jsonl|csv>'));
  });
}
