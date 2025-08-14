import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/l3/ev/jam_fold_model.dart';
import 'package:poker_analyzer/l3/jam_fold_evaluator.dart';
import 'package:poker_analyzer/utils/board_textures.dart';

double _sprFromBoard(String board) {
  final hash = board.codeUnits.fold<int>(0, (a, b) => a + b);
  return 0.5 + (hash % 300) / 100.0; // 0.5 - 3.5
}

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('in', defaultsTo: 'build/reports/l3_packrun.json')
    ..addOption('out', defaultsTo: 'build/reports/l3_packrun_ev.json')
    ..addOption('weights')
    ..addOption('weightsPreset', defaultsTo: 'default', allowed: ['aggro', 'nitty', 'default'])
    ..addOption('priors')
    ..addFlag('explain', negatable: false);
  final res = parser.parse(args);

  final inPath = res['in'] as String;
  final outPath = res['out'] as String;

  Map<String, double>? weights;
  final weightsOpt = res['weights'] as String?;
  final presetOpt = res['weightsPreset'] as String?;
  if (weightsOpt != null) {
    final jsonStr = weightsOpt.trim().startsWith('{')
        ? weightsOpt
        : File(weightsOpt).readAsStringSync();
    weights = (json.decode(jsonStr) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  } else if (presetOpt != null) {
    final presetPath = {
      'aggro': 'tool/config/weights/aggro.json',
      'nitty': 'tool/config/weights/nitty.json',
      'default': 'tool/config/weights/default.json',
    }[presetOpt]!;
    final jsonStr = File(presetPath).readAsStringSync();
    weights = (json.decode(jsonStr) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Map<String, double>? priors;
  final priorsOpt = res['priors'] as String?;
  if (priorsOpt != null) {
    final jsonStr = priorsOpt.trim().startsWith('{')
        ? priorsOpt
        : File(priorsOpt).readAsStringSync();
    priors = (json.decode(jsonStr) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  final explain = res['explain'] as bool;
  final model = JamFoldModel(weights: weights);

  final input = json.decode(File(inPath).readAsStringSync());
  final spots = (input['spots'] as List?) ?? <dynamic>[];

  final outSpots = <Map<String, dynamic>>[];
  final sprHistogram = {'spr_low': 0, 'spr_mid': 0, 'spr_high': 0};
  final textureCounts = <String, int>{};
  var jamCount = 0;

  for (final raw in spots) {
    if (raw is! Map) continue;
    final boardCards = parseBoard(raw['board']).take(3).toList();
    if (boardCards.length < 3) continue;
    final boardStr = boardCards.join();
    final board = FlopBoard.fromString(boardStr);
    final spr = _sprFromBoard(boardStr);
    final eval = model.evaluate(
      board: board,
      spr: spr,
      priors: priors,
      explain: explain,
    );
    if (eval['decision'] == 'jam') {
      jamCount++;
    }
    final sprBucket = spr < 1
        ? 'spr_low'
        : spr < 2
            ? 'spr_mid'
            : 'spr_high';
    sprHistogram[sprBucket] = (sprHistogram[sprBucket] ?? 0) + 1;
    for (final t in board.tags) {
      textureCounts[t] = (textureCounts[t] ?? 0) + 1;
    }
    final spotOut = Map<String, dynamic>.from(raw)
      ..['decision'] = eval['decision']
      ..['jamEV'] = eval['jamEV']
      ..['foldEV'] = eval['foldEV']
      ..['spr'] = spr;
    if (explain) {
      spotOut['explain'] = eval['explain'];
    }
    outSpots.add(spotOut);
  }

  final summary = {
    'total': outSpots.length,
    'jamRate': outSpots.isEmpty ? 0 : jamCount / outSpots.length,
    'sprHistogram': sprHistogram,
    'textureCounts': textureCounts,
  };

  final report = {'spots': outSpots, 'summary': summary};
  final outFile = File(outPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(json.encode(report));
}
