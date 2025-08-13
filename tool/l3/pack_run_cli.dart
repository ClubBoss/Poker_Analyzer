import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'package:poker_analyzer/l3/jam_fold_evaluator.dart';
import 'package:poker_analyzer/services/autogen_v4.dart';
import 'package:poker_analyzer/services/autogen_stats.dart';
import 'package:poker_analyzer/services/l3_cli_runner.dart'
    show extractTargetMix;

double _sprFromBoard(String board) {
  final hash = board.codeUnits.fold<int>(0, (a, b) => a + b);
  return 0.5 + (hash % 300) / 100.0; // 0.5 - 3.5
}

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('dir', defaultsTo: 'build/tmp/l3/111')
    ..addOption('out', defaultsTo: 'build/reports/l3_packrun.json')
    ..addOption('weights')
    ..addOption('weightsPreset', allowed: ['aggro', 'nitty', 'default'])
    ..addOption('priors')
    ..addOption('seed')
    ..addOption('count')
    ..addOption('preset', defaultsTo: 'postflop_default')
    ..addOption('targetMix')
    ..addFlag('explain', negatable: false);
  final res = parser.parse(args);
  final outPath = res['out'] as String;

  // Autogen v4 path: generate boards and emit report
  final countOpt = res['count'] as String?;
  final presetArg = res['preset'] as String?;
  final seedOpt = res['seed'] as String?;
  final targetMixOpt = res['targetMix'] as String?;
  if (countOpt != null) {
    final count = int.tryParse(countOpt) ?? 0;
    final seed = int.tryParse(seedOpt ?? '');
    Map<String, double>? mix;
    if (targetMixOpt != null) {
      final cfg = extractTargetMix(targetMixOpt);
      mix = cfg?.mix;
    }
    final gen = BoardStreetGenerator(seed: seed, targetMix: mix);
    final spots = gen.generate(
      count: count,
      preset: presetArg ?? 'postflop_default',
    );
    final report = {
      'spots': spots,
      'autogen': {
        'seed': seed,
        'count': count,
        'preset': presetArg ?? 'postflop_default',
      },
    };
    final stats = buildAutogenStats(jsonEncode(report));
    if (stats != null) {
      (report['autogen'] as Map<String, dynamic>)['stats'] = {
        'total': stats.total,
        'textures': stats.textures,
      };
    }
    final outFile = File(outPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(jsonEncode(report));
    return;
  }

  final dir = res['dir'] as String;

  JamFoldEvaluator evaluator;
  final weightsOpt = res['weights'] as String?;
  final presetOpt = res['weightsPreset'] as String?;
  if (weightsOpt != null && presetOpt != null) {
    stderr.writeln(
      "[pack_run_cli] both --weights and --weightsPreset provided; using --weights",
    );
  }
  if (weightsOpt != null) {
    final jsonStr = weightsOpt.trim().startsWith('{')
        ? weightsOpt
        : File(weightsOpt).readAsStringSync();
    final decoded = (json.decode(jsonStr) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    evaluator = JamFoldEvaluator.fromWeights(decoded);
  } else if (presetOpt != null) {
    final presetPath = {
      'aggro': 'tool/config/weights/aggro.json',
      'nitty': 'tool/config/weights/nitty.json',
      'default': 'tool/config/weights/default.json',
    }[presetOpt]!;
    final jsonStr = File(presetPath).readAsStringSync();
    final decoded = (json.decode(jsonStr) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    evaluator = JamFoldEvaluator.fromWeights(decoded);
  } else {
    evaluator = JamFoldEvaluator();
  }

  Map<String, double>? priors;
  final priorsOpt = res['priors'] as String?;
  if (priorsOpt != null) {
    final jsonStr = priorsOpt.trim().startsWith('{')
        ? priorsOpt
        : File(priorsOpt).readAsStringSync();
    final decoded = (json.decode(jsonStr) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    priors = decoded;
  }

  final explain = res['explain'] as bool;
  final outSpots = <Map<String, dynamic>>[];
  final textureCounts = <String, int>{};
  final presetCounts = <String, int>{};
  final sprHistogram = <String, int>{'spr_low': 0, 'spr_mid': 0, 'spr_high': 0};
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
        late final String sprBucket;
        if (spr < 1.0) {
          sprBucket = 'spr_low';
        } else if (spr < 2.0) {
          sprBucket = 'spr_mid';
        } else {
          sprBucket = 'spr_high';
        }
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
