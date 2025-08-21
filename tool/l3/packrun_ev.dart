import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/l3/ev/jam_fold_model.dart';
import 'package:poker_analyzer/l3/jam_fold_evaluator.dart'; // FlopBoard
import 'package:poker_analyzer/utils/board_textures.dart'; // parseBoard, classifyFlop

double _sprFromBoard(String board) {
  final hash = board.codeUnits.fold<int>(0, (a, b) => a + b);
  return 0.5 + (hash % 300) / 100.0; // 0.5 - 3.5
}

Map<String, double> _decodeDoubleMap(String jsonStr) {
  return (json.decode(jsonStr) as Map<String, dynamic>).map(
    (k, v) => MapEntry(k, (v as num).toDouble()),
  );
}

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('in', defaultsTo: 'build/reports/l3_packrun.json')
    ..addOption('out', defaultsTo: 'build/reports/l3_packrun_ev.json')
    ..addOption('weights')
    ..addOption(
      'weightsPreset',
      defaultsTo: 'default',
      allowed: ['aggro', 'nitty', 'default'],
    )
    ..addOption('priors')
    ..addFlag('explain', negatable: false);
  final res = parser.parse(args);

  final inPath = res['in'] as String;
  final outPath = res['out'] as String;

  // Weights
  Map<String, double>? weights;
  final weightsOpt = res['weights'] as String?;
  if (weightsOpt != null) {
    final jsonStr = weightsOpt.trim().startsWith('{')
        ? weightsOpt
        : File(weightsOpt).readAsStringSync();
    weights = _decodeDoubleMap(jsonStr);
  } else {
    final preset =
        res['weightsPreset'] as String; // guaranteed by parser defaults
    final presetPath = {
      'aggro': 'tool/config/weights/aggro.json',
      'nitty': 'tool/config/weights/nitty.json',
      'default': 'tool/config/weights/default.json',
    }[preset]!;
    final jsonStr = File(presetPath).readAsStringSync();
    weights = _decodeDoubleMap(jsonStr);
  }

  // Priors (optional)
  Map<String, double>? priors;
  final priorsOpt = res['priors'] as String?;
  if (priorsOpt != null) {
    final jsonStr = priorsOpt.trim().startsWith('{')
        ? priorsOpt
        : File(priorsOpt).readAsStringSync();
    priors = _decodeDoubleMap(jsonStr);
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

    // Поддерживаем оба кодирования борда: List<String> или String
    final rb = raw['board'];
    List<String> board3;
    if (rb is List) {
      board3 = rb.cast<String>().take(3).toList();
    } else if (rb is String) {
      board3 = parseBoard(rb).take(3).toList();
    } else {
      continue;
    }
    if (board3.length < 3) continue;

    final boardStr = board3.join();
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

    // Канонические ключи текстур
    final textures = classifyFlop(board3);
    for (final tex in textures) {
      textureCounts[tex.name] = (textureCounts[tex.name] ?? 0) + 1;
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
