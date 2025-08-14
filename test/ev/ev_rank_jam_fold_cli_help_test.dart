import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('--help prints usage', () async {
    final dart = Platform.resolvedExecutable;
    final result = await Process.run(dart, [
      'run',
      'bin/ev_rank_jam_fold_deltas.dart',
      '--help',
    ]);
    expect(result.exitCode, 0);
    final stdoutStr = result.stdout as String;
    expect(stdoutStr, contains('Usage:'));
    expect(stdoutStr, contains('--dir <dir>'));
    expect(stdoutStr, contains('--format <json|jsonl|csv>'));
  });

  test('-h prints usage', () async {
    final dart = Platform.resolvedExecutable;
    final result = await Process.run(dart, [
      'run',
      'bin/ev_rank_jam_fold_deltas.dart',
      '-h',
    ]);
    expect(result.exitCode, 0);
    final stdoutStr = result.stdout as String;
    expect(stdoutStr, contains('Usage:'));
  });
}
