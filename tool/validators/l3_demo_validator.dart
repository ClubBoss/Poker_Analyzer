import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('dir', defaultsTo: 'assets/packs/l3/demo')
    ..addOption('dedupe', defaultsTo: 'flop', allowed: ['flop', 'board']);
  final res = parser.parse(args);
  final dirPath = res['dir'] as String;
  final dedupe = res['dedupe'] as String;

  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: $dirPath');
    exit(1);
  }

  var hasError = false;
  for (final file in dir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.yaml'),
      )) {
    final content = loadYaml(file.readAsStringSync()) as Map;
    final subtype = content['subtype'];
    final street = content['street'];
    if (subtype != 'postflop-jam' || street != 'flop') {
      stderr.writeln('::error::${file.path} has invalid subtype/street');
      hasError = true;
    }
    final spots = List.from(content['spots'] as List? ?? []);
    if (spots.length < 80 || spots.length > 120) {
      stderr.writeln('::error::${file.path} has ${spots.length} spots');
      hasError = true;
    }
    final seenFlops = <String>{};
    final seenBoards = <String>{};
    for (final s in spots) {
      final spot = s as Map;
      final actionType = spot['actionType'];
      final board = spot['board'] as String?;
      final tags = List.from(spot['tags'] as List? ?? []);
      if (actionType != 'postflop-jam' || board == null || tags.isEmpty) {
        stderr.writeln('::error::${file.path} has invalid spot');
        hasError = true;
        continue;
      }
      if (!tags.contains('monotone') &&
          !tags.contains('twoTone') &&
          !tags.contains('rainbow')) {
        stderr.writeln('::error::${file.path} spot $board missing texture tag');
        hasError = true;
      }
      if (tags.any((t) => (t as String).isEmpty)) {
        stderr.writeln('::error::${file.path} spot $board has empty tag');
        hasError = true;
      }
      final flop = board.substring(0, 6);
      if (dedupe == 'flop') {
        if (!seenFlops.add(flop)) {
          stderr.writeln('::error::${file.path} duplicate flop $flop');
          hasError = true;
        }
      } else {
        if (!seenBoards.add(board)) {
          stderr.writeln('::error::${file.path} duplicate board $board');
          hasError = true;
        }
      }
    }
  }
  if (hasError) exit(1);
}
