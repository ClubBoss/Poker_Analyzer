import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('report', defaultsTo: 'theory_sweep_report.json')
    ..addFlag('markdown', negatable: false)
    ..addOption('mode',
        allowed: ['soft', 'strict'], defaultsTo: 'strict');
  final opts = parser.parse(args);

  final mode = opts['mode'] as String;
  stdout.writeln('mode=$mode');

  final reportFile = File(opts['report'] as String);
  if (!reportFile.existsSync()) {
    if (mode == 'soft') {
      stdout.writeln('\x1B[33mSOFT OK: no YAML to verify\x1B[0m');
      return;
    }
    stderr.writeln('no report');
    exitCode = 1;
    return;
  }
  final data =
      jsonDecode(await reportFile.readAsString()) as Map<String, dynamic>;
  final entries =
      (data['entries'] as List? ?? []).cast<Map<String, dynamic>>();

  if (entries.isEmpty) {
    if (mode == 'soft') {
      stdout.writeln('\x1B[33mSOFT OK: no YAML to verify\x1B[0m');
      return;
    }
    stderr.writeln('no entries');
    exitCode = 1;
    return;
  }

  final issues = <String, List<String>>{
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
    stderr.writeln('::${level} file=$file::$msg');
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
        buffer.writeln('  - `${f}`');
      }
    }
    stdout.write(buffer.toString());
  }
}

