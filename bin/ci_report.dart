import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('report', defaultsTo: 'theory_sweep_report.json')
    ..addFlag('markdown', negatable: false);
  final opts = parser.parse(args);

  final reportFile = File(opts['report'] as String);
  if (!reportFile.existsSync()) {
    stdout.writeln('no report');
    return;
  }
  final data =
      jsonDecode(await reportFile.readAsString()) as Map<String, dynamic>;
  final entries =
      (data['entries'] as List? ?? []).cast<Map<String, dynamic>>();

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

  if (opts['markdown'] as bool) {
    final buffer = StringBuffer('### Theory Sweep Summary\n');
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

