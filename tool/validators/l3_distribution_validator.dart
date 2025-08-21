import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../autogen/l3_presets.dart';

String _texture(String board) {
  final flop = [
    board.substring(0, 2),
    board.substring(2, 4),
    board.substring(4, 6),
  ];
  final suits = flop.map((c) => c[1]).toSet();
  if (suits.length == 1) return 'monotone';
  if (suits.length == 2) return 'twoTone';
  return 'rainbow';
}

Map<String, double> _parseTargetMix(String arg) {
  final file = File(arg);
  final content = file.existsSync() ? file.readAsStringSync() : arg;
  final decoded = json.decode(content) as Map<String, dynamic>;
  return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
}

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('dir', defaultsTo: 'build/tmp/l3')
    ..addOption('targetMix')
    ..addOption('tolerance', defaultsTo: '0.1')
    ..addOption('dedupe', defaultsTo: 'flop', allowed: ['flop', 'board']);
  final res = parser.parse(args);
  final rootDir = res['dir'] as String;
  final tol = double.parse(res['tolerance'] as String);
  final targetMixArg = res['targetMix'] as String?;
  final dedupe = res['dedupe'] as String;

  final dir = Directory(rootDir);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: $rootDir');
    exit(1);
  }

  var hasError = false;
  for (final file in dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'))) {
    final preset = p.basename(p.dirname(file.path));
    final presetDef = l3Presets[preset];
    if (presetDef == null) continue;
    final mix = targetMixArg != null
        ? _parseTargetMix(targetMixArg)
        : presetDef.targetMix;
    final content = loadYaml(file.readAsStringSync()) as Map;
    final spots = content['spots'] as List?;
    if (spots == null || spots.isEmpty) {
      stderr.writeln('Pack ${file.path} has no spots');
      hasError = true;
      continue;
    }
    if (spots.length != 100) {
      stderr.writeln(
        'Pack ${file.path} has ${spots.length} spots, expected 100',
      );
      hasError = true;
    }
    final counts = <String, int>{};
    final seenFlops = <String>{};
    final seenBoards = <String>{};
    for (final s in spots) {
      final board = s['board'] as String?;
      if (board == null) continue;
      final flop = board.substring(0, 6);
      if (dedupe == 'flop') {
        if (!seenFlops.add(flop)) {
          stderr.writeln('Duplicate flop $flop in ${file.path}');
          hasError = true;
        }
      } else {
        if (!seenBoards.add(board)) {
          stderr.writeln('Duplicate board $board in ${file.path}');
          hasError = true;
        }
      }
      final t = _texture(board);
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final total = spots.length;
    for (final entry in mix.entries) {
      final actual = (counts[entry.key] ?? 0) / total;
      stdout.writeln(
        '::notice::${preset} ${entry.key} ${actual.toStringAsFixed(2)}',
      );
      final diff = (actual - entry.value).abs();
      if (diff > tol) {
        stderr.writeln(
          '::warning::${preset} ${entry.key} expected ${entry.value.toStringAsFixed(2)} actual ${actual.toStringAsFixed(2)}',
        );
        hasError = true;
      }
    }
  }
  if (hasError) exit(1);
}
