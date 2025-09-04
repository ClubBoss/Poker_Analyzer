// ASCII-only; pure Dart CLI.
// Scaffolds placeholder content for Live modules.

import 'dart:io';

import 'package:poker_analyzer/live/live_ids.dart';

void main(List<String> args) async {
  final force = args.contains('--force');

  try {
    for (final id in kLiveModuleIds) {
      final dir = Directory('content/$id/v1');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Files to create per module
      final theoryPath = '${dir.path}/theory.md';
      final demosPath = '${dir.path}/demos.jsonl';
      final drillsPath = '${dir.path}/drills.jsonl';

      await _writeFile(
        path: theoryPath,
        contents: _theoryPlaceholder(id),
        force: force,
      );

      await _writeFile(
        path: demosPath,
        contents: _demosPlaceholder(id),
        force: force,
      );

      await _writeFile(
        path: drillsPath,
        contents: _drillsPlaceholder(id),
        force: force,
      );
    }
  } on IOException catch (e) {
    stderr.writeln('IO ERROR: ${e.toString()}');
    exitCode = 1;
    return;
  } catch (e) {
    stderr.writeln('ERROR: ${e.toString()}');
    exitCode = 1;
    return;
  }
}

Future<void> _writeFile({
  required String path,
  required String contents,
  required bool force,
}) async {
  final file = File(path);
  final exists = await file.exists();
  if (exists && !force) {
    stdout.writeln('SKIP $path');
    return;
  }
  await file.writeAsString(contents, flush: true);
  stdout.writeln('OK $path');
}

String _theoryPlaceholder(String id) {
  // 6-8 lines, ASCII-only.
  return [
        '# $id - Theory (placeholder)',
        'PHASE: SKELETON ONLY',
        'This file will be replaced by Research batches.',
        'Length target: 400-700 words.',
        'Notes: keep structure simple and clear.',
        'Authoring status: pending research import.',
      ].join('\n') +
      '\n';
}

String _demosPlaceholder(String id) {
  final header = '# demos for $id (placeholder)';
  final json = '{"id":"${id}_demo_001","title":"PLACEHOLDER","body":"TBD"}';
  return header + '\n' + json + '\n';
}

String _drillsPlaceholder(String id) {
  final header = '# drills for $id (placeholder)';
  final json = '{"id":"${id}_drill_001","prompt":"TBD","answer":"TBD"}';
  return header + '\n' + json + '\n';
}
