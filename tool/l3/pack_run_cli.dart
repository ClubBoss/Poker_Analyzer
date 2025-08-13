import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'package:poker_analyzer/l3/jam_fold_evaluator.dart';

double _sprFromBoard(String board) {
  final hash = board.codeUnits.fold<int>(0, (a, b) => a + b);
  return 0.5 + (hash % 300) / 100.0; // 0.5 - 3.5
}

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('dir', defaultsTo: 'build/tmp/l3/111')
    ..addOption('out', defaultsTo: 'build/reports/l3_packrun.json');
  final res = parser.parse(args);
  final dir = res['dir'] as String;
  final outPath = res['out'] as String;

  final evaluator = JamFoldEvaluator();
  final outSpots = <Map<String, dynamic>>[];
  final textureCounts = <String, int>{};
  int jamCount = 0;

  try {
    final yamlFiles = Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml'));
    for (final file in yamlFiles) {
      final doc = loadYaml(file.readAsStringSync()) as YamlMap;
      final spots = doc['spots'] as YamlList?;
      if (spots == null) continue;
      for (final spot in spots) {
        final s = spot as YamlMap;
        final id = s['id'] as String;
        final boardStr = s['board'] as String;
        final tags = (s['tags'] as YamlList?)?.cast<String>() ?? <String>[];
        final texture = tags.firstWhere(
            (t) => t == 'monotone' || t == 'twoTone' || t == 'rainbow',
            orElse: () => 'unknown');
        textureCounts[texture] = (textureCounts[texture] ?? 0) + 1;
        final spr = _sprFromBoard(boardStr);
        final outcome = evaluator.evaluate(
          board: FlopBoard.fromString(boardStr),
          spr: spr,
        );
        if (outcome.decision == 'jam') jamCount++;
        outSpots.add({
          'id': id,
          'board': boardStr,
          'decision': outcome.decision,
          'jamEV': outcome.jamEV,
          'foldEV': outcome.foldEV,
        });
      }
    }
    final summary = {
      'total': outSpots.length,
      'avgJamRate': outSpots.isEmpty ? 0 : jamCount / outSpots.length,
      'textureCounts': textureCounts,
      'accuracy': {'jam': 0, 'fold': 0},
    };
    final report = {'spots': outSpots, 'summary': summary};
    final outFile = File(outPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(jsonEncode(report));
  } catch (e) {
    stderr.writeln('Parse error: $e');
    exit(1);
  }
}
