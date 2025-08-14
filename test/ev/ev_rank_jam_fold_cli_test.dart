import 'dart:io';

import 'package:test/test.dart';

final _repoRoot = Directory.current.path;
String get _dartExe => Platform.resolvedExecutable;

Future<ProcessResult> _run(List<String> args) {
  return Process.run(
    _dartExe,
    ['run', 'bin/ev_rank_jam_fold_deltas.dart', ...args],
    workingDirectory: _repoRoot,
  );
}

void main() {
  group('ev_rank_jam_fold_deltas CLI', () {
    test('prints usage with --help', () async {
      final r = await _run(['--help']);
      expect(r.exitCode, 0);
      expect((r.stdout ?? '').toString(), contains('Usage:'));
    });

    test('fails gracefully on invalid flag', () async {
      final r = await _run(['--fail-under', 'nope']);
      // ожидаем ненулевой код выхода (64 = usage error)
      expect(r.exitCode, isNonZero);
      final out = (r.stdout ?? '').toString() + (r.stderr ?? '').toString();
      expect(
          out,
          anyOf(contains('Invalid --fail-under'),
              contains('Unknown or incomplete argument')));
    });
  });
}
