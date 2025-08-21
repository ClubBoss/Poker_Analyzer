import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('source', defaultsTo: 'build/tmp/l3')
    ..addOption(
      'preset',
      defaultsTo: 'all',
      allowed: ['paired', 'unpaired', 'ace-high', 'all'],
    )
    ..addOption('out', defaultsTo: 'assets/packs/l3/demo')
    ..addOption('spots', defaultsTo: '100')
    ..addOption('dedupe', defaultsTo: 'flop', allowed: ['flop', 'board'])
    ..addOption('seed', defaultsTo: '111');
  final res = parser.parse(args);
  final sourceArg = res['source'] as String;
  final presetArg = res['preset'] as String;
  final outDir = res['out'] as String;
  final spotCount = int.parse(res['spots'] as String);
  final dedupe = res['dedupe'] as String;
  final seed = int.parse(res['seed'] as String);

  final source = _resolveSource(sourceArg);
  final presets = presetArg == 'all'
      ? ['paired', 'unpaired', 'ace-high']
      : [presetArg];

  final out = Directory(outDir);
  out.createSync(recursive: true);

  var hasError = false;
  for (final preset in presets) {
    final file = File(
      p.join(
        source.path,
        'postflop-jam',
        preset,
        'l3-postflop-jam-$preset.yaml',
      ),
    );
    if (!file.existsSync()) {
      stderr.writeln('Missing source pack for preset $preset at ${file.path}');
      hasError = true;
      continue;
    }
    final content = loadYaml(file.readAsStringSync()) as Map;
    final spots = List.from(content['spots'] as List? ?? []);
    if (spots.isEmpty) {
      stderr.writeln('Source pack ${file.path} has no spots');
      hasError = true;
      continue;
    }
    spots.shuffle(Random(seed));
    final selected = spots.take(spotCount).toList();
    selected.sort((a, b) {
      final boardA = a['board'] as String? ?? '';
      final boardB = b['board'] as String? ?? '';
      return boardA.compareTo(boardB);
    });

    final seenFlops = <String>{};
    final seenBoards = <String>{};
    final sb = StringBuffer();
    final packId = 'l3-demo-$preset';
    sb.writeln('id: $packId');
    sb.writeln('stage:');
    sb.writeln('  id: L3');
    sb.writeln('subtype: postflop-jam');
    sb.writeln('street: flop');
    sb.writeln('tags:');
    sb.writeln('  - l3');
    sb.writeln('  - demo');
    sb.writeln('  - $preset');
    sb.writeln('spots:');
    for (var i = 0; i < selected.length; i++) {
      final spot = selected[i] as Map;
      final board = spot['board'] as String?;
      final actionType = spot['actionType'] as String?;
      final tags = List.from(spot['tags'] as List? ?? []);
      tags.removeWhere((t) => t == 'l3');
      if (board == null || actionType != 'postflop-jam' || tags.isEmpty) {
        stderr.writeln('Invalid spot in ${file.path}: $spot');
        hasError = true;
        continue;
      }
      final flop = board.substring(0, 6);
      if (dedupe == 'flop') {
        if (!seenFlops.add(flop)) {
          stderr.writeln('Duplicate flop $flop in preset $preset');
          hasError = true;
        }
      } else {
        if (!seenBoards.add(board)) {
          stderr.writeln('Duplicate board $board in preset $preset');
          hasError = true;
        }
      }
      final spotId = '${packId}-s${(i + 1).toString().padLeft(3, '0')}';
      sb.writeln('  -');
      sb.writeln('    id: $spotId');
      sb.writeln('    actionType: postflop-jam');
      sb.writeln('    board: $board');
      sb.writeln('    tags:');
      for (final t in tags) {
        sb.writeln('      - $t');
      }
    }
    final outFile = File(p.join(out.path, '$packId.yaml'));
    outFile.writeAsStringSync(sb.toString());
    if (selected.isEmpty) {
      stderr.writeln('No spots selected for preset $preset');
      hasError = true;
    }
  }
  if (hasError) exit(1);
}

Directory _resolveSource(String sourceArg) {
  final dir = Directory(sourceArg);
  if (!dir.existsSync()) {
    stderr.writeln('Source directory not found: ${dir.path}');
    exit(1);
  }
  final seeds = dir
      .listSync()
      .whereType<Directory>()
      .where((d) => int.tryParse(p.basename(d.path)) != null)
      .toList();
  if (seeds.isEmpty) return dir;
  seeds.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
  return seeds.last;
}
