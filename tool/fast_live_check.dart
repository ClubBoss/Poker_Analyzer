// Fast lane for Live checks: pure Dart, ASCII-only.
// Runs format, analyze, and a scoped set of tests without Flutter.

import 'dart:io';

Future<void> main(List<String> args) async {
  final failFast =
      args.contains('--fail-fast') || !args.contains('--no-fail-fast');
  final doFormat = !args.contains('--no-format');
  final doAnalyze = !args.contains('--no-analyze');
  final doTest = !args.contains('--no-test');

  final steps = <_Step>[
    if (doFormat)
      _Step(
        label: 'FORMAT',
        command: 'dart',
        arguments: [
          'format',
          '--set-exit-if-changed',
          'lib/live/',
          ..._expandLiveTestGlobs(),
        ],
      ),
    if (doAnalyze)
      _Step(
        label: 'ANALYZE',
        command: 'dart',
        arguments: [
          'analyze',
          'lib/live/',
          ..._expandLiveTestGlobs(),
          'lib/telemetry/telemetry.dart',
        ],
      ),
    if (doTest)
      _Step(
        label: 'TESTS',
        command: 'dart',
        arguments: [
          'test',
          '-r',
          'expanded',
          // Hardcoded, append-only list for determinism.
          'test/live_context_test.dart',
          'test/live_validators_test.dart',
          'test/live_messages_test.dart',
          'test/live_defaults_test.dart',
          'test/live_runtime_test.dart',
          'test/live_integration_test.dart',
          'test/live_actions_test.dart',
          'test/live_ids_consistency_test.dart',
          'test/live_progress_test.dart',
          'test/live_telemetry_test.dart',
          'test/live_barrel_test.dart',
          'test/live_no_flutter_imports_test.dart',
        ],
      ),
  ];

  var exitCodeOverall = 0;
  for (final step in steps) {
    final result = await _run(step.command, step.arguments);
    final pass = result.exitCode == 0;
    stdout.writeln('${step.label}: ${pass ? 'PASS' : 'FAIL'}');
    if (!pass) {
      exitCodeOverall = 1;
      if (failFast) {
        exit(1);
      }
    }
  }

  exit(exitCodeOverall);
}

class _Step {
  final String label; // FORMAT, ANALYZE, TESTS
  final String command;
  final List<String> arguments;
  _Step({required this.label, required this.command, required this.arguments});
}

Future<ProcessResult> _run(String cmd, List<String> args) {
  return Process.run(cmd, args);
}

List<String> _expandLiveTestGlobs() {
  // Emulate the shell glob: test/live_* (non-recursive).
  final dir = Directory('test');
  if (!dir.existsSync()) return <String>['test/live_*'];
  final entries =
      dir
          .listSync(followLinks: false)
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => p.startsWith('test/live_') && p.endsWith('.dart'))
          .toList()
        ..sort();
  return entries.isEmpty ? <String>['test/live_*'] : entries;
}

// No headers/footers to keep output terse and ASCII-only.
