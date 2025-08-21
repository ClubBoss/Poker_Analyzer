import 'dart:io';

import 'package:test/test.dart';

final _repoRoot = Directory.current.path;

/// Returns the path to the Dart executable.
String get _dartExe => Platform.resolvedExecutable;

/// Runs a CLI with `--help` and returns exitCode + stdout.
Future<ProcessResult> _runHelp(String scriptPath) {
  return Process.run(_dartExe, [
    'run',
    scriptPath,
    '--help',
  ], workingDirectory: _repoRoot);
}

void main() {
  group('cli --help prints usage', () {
    test('ev_rank_jam_fold_deltas.dart', () async {
      final r = await _runHelp('bin/ev_rank_jam_fold_deltas.dart');
      // Expect success-like exit and some usage content printed
      expect(r.exitCode, anyOf(0, 0)); // keep strictly 0
      expect((r.stdout ?? '').toString(), contains('Usage:'));
    });

    // при необходимости просто раскомментируй ниже ещё CLI
    // test('ev_summary_jam_fold.dart', () async {
    //   final r = await _runHelp('bin/ev_summary_jam_fold.dart');
    //   expect(r.exitCode, 0);
    //   expect((r.stdout ?? '').toString(), contains('Usage:'));
    // });
    //
    // test('ev_enrich_jam_fold.dart', () async {
    //   final r = await _runHelp('bin/ev_enrich_jam_fold.dart');
    //   expect(r.exitCode, 0);
    //   expect((r.stdout ?? '').toString(), contains('Usage:'));
    // });
  });
}
