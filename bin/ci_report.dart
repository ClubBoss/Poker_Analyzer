import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../tool/metrics/recall_accuracy_aggregator.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('report', defaultsTo: 'theory_sweep_report.json')
    ..addFlag('markdown', negatable: false)
    ..addOption('mode', allowed: ['soft', 'strict'], defaultsTo: 'strict');
  final opts = parser.parse(args);

  final mode = opts['mode'] as String;
  stdout.writeln('mode=$mode');

  // --- Run lightweight validators (packs + smoke) ---
  final validators = [
    ['dart', 'run', 'tool/validators/packs_validator.dart'],
    ['dart', 'run', 'tool/validators/smoke_gen.dart'],
  ];
  var validatorFailed = false;
  for (final cmd in validators) {
    final r = await Process.run(cmd[0], cmd.sublist(1));
    stdout.write(r.stdout);
    stderr.write(r.stderr);
    if (r.exitCode != 0) {
      validatorFailed = true;
    }
  }
  Map<String, List<String>> issues = {};
  if (!(validatorFailed && mode == 'strict')) {
    final reportFile = File(opts['report'] as String);
    if (!reportFile.existsSync()) {
      if (mode == 'soft') {
        stdout.writeln('\x1B[33mSOFT OK: no YAML to verify\x1B[0m');
      } else {
        stderr.writeln('no report');
        exitCode = 1;
      }
    } else {
      final data =
          jsonDecode(await reportFile.readAsString()) as Map<String, dynamic>;
      final entries =
          (data['entries'] as List? ?? const []).cast<Map<String, dynamic>>();
      if (entries.isEmpty) {
        if (mode == 'soft') {
          stdout.writeln('\x1B[33mSOFT OK: no YAML to verify\x1B[0m');
        } else {
          stderr.writeln('no entries');
          exitCode = 1;
        }
      } else {
        issues = <String, List<String>>{
          'needs_upgrade': [],
          'needs_heal': [],
          'failed': [],
        };
        for (final e in entries) {
          final action = e['action'] as String? ?? '';
          if (!issues.containsKey(action)) continue;
          final file = p.relative(e['file'] as String? ?? '');
          final oldHash = e['oldHash'] ?? '';
          final newHash = e['newHash'] ?? '';
          final msg = '$action: $oldHash -> $newHash';
          final level = action == 'needs_upgrade' ? 'warning' : 'error';
          stderr.writeln('::$level file=$file::$msg');
          issues[action]!.add(file);
        }
        final hasIssues = issues.values.any((l) => l.isNotEmpty);
        if (hasIssues && mode == 'strict') {
          exitCode = 1;
        }
        if (opts['markdown'] as bool) {
          final buffer = StringBuffer('### Theory Sweep Summary\n')
            ..writeln('- mode=$mode');
          for (final entry in issues.entries) {
            if (entry.value.isEmpty) continue;
            buffer.writeln('- **${entry.key}**');
            for (final f in entry.value) {
              buffer.writeln('  - `$f`');
            }
          }
          stdout.write(buffer.toString());
        }
      }
    }
  } else {
    exitCode = 1;
  }

  // --- Inline recall accuracy summary (best-effort) ---
  final recallSummary = RecallAccuracyAggregator().summarize('l2');
  if (recallSummary.isNotEmpty) stdout.writeln(recallSummary);
}
