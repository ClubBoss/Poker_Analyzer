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
    ..addOption('out', defaultsTo: 'build/reports/l3_packrun.json')
    ..addOption('weights')
    ..addOption('priors')
    ..addFlag('explain', negatable: false);
  final res = parser.parse(args);
  final dir = res['dir'] as String;
  final outPath = res['out'] as String;

  JamFoldEvaluator evaluator;
  final weightsOpt = res['weights'] as String?;
  if (weightsOpt != null) {
    final jsonStr = weightsOpt.trim().startsWith('{')
        ? weightsOpt
        : File(weightsOpt).readAsStringSync();
    final decoded = (json.decode(jsonStr) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
    evaluator = JamFoldEvaluator.fromWeights(decoded);
  } else {
    evaluator = JamFoldEvaluator();
  }

  Map<String, double>? priors;
  final priorsOpt = res['priors'] as String?;
  if (priorsOpt != null) {
    final decoded = (json.decode(priorsOpt) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
    priors = decoded;
  }

  final explain = res['explain'] as bool;
  final outSpots = <Map<String, dynamic>>[];
  final textureCounts = <String, int>{};
  final presetCounts = <String, int>{};
  final sprHistogram = <String, int>{
    'spr_low': 0,
    'spr_mid': 0,
    'spr_high': 0,
  };
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

      final docTags = (doc['tags'] as YamlList?)?.cast<String>() ?? <String>[];
      var preset = docTags.firstWhere(
        (t) => t == 'paired' || t == 'unpaired' || t == 'ace-high',
        orElse: () => 'unknown',
      );
      if (preset == 'unknown') {
        final match = RegExp(r'postflop-jam/([^/]+)/').firstMatch(file.path);
        preset = match?.group(1) ?? 'unknown';
      }

      for (final spot in spots) {
        final s = spot as YamlMap;
        final id = s['id'] as String;
        final boardStr = s['board'] as String;
        final tags = (s['tags'] as YamlList?)?.cast<String>() ?? <String>[];
        final texture = tags.firstWhere(
          (t) => t == 'monotone' || t == 'twoTone' || t == 'rainbow',
          orElse: () => 'unknown',
        );
        textureCounts[texture] = (textureCounts[texture] ?? 0) + 1;
        final spr = _sprFromBoard(boardStr);
        presetCounts[preset] = (presetCounts[preset] ?? 0) + 1;
        final sprBucket = spr < 1.0
            ? 'spr_low'
            : spr < 2.0
                ? 'spr_mid'
                : 'spr_high';
        sprHistogram[sprBucket] = (sprHistogram[sprBucket] ?? 0) + 1;
        final outcome = evaluator.evaluate(
          board: FlopBoard.fromString(boardStr),
          spr: spr,
          priors: priors,
        );
        if (outcome.decision == 'jam') jamCount++;
        final spotObj = {
          'id': id,
          'board': boardStr,
          'decision': outcome.decision,
          'jamEV': outcome.jamEV,
          'foldEV': outcome.foldEV,
          'spr': spr,
        };
        if (explain) {
          spotObj['explain'] = {
            'sprBucket': outcome.sprBucket,
            'tags': outcome.tagsUsed,
            'contrib': outcome.contrib,
          };
        }
        outSpots.add(spotObj);
      }
    }
    final summary = {
      'total': outSpots.length,
      'avgJamRate': outSpots.isEmpty ? 0 : jamCount / outSpots.length,
      'textureCounts': textureCounts,
      'presetCounts': presetCounts,
      'sprHistogram': sprHistogram,
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
