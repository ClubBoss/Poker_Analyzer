import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/services/autogen_v4.dart';
import 'package:poker_analyzer/services/autogen_stats.dart';
import 'package:poker_analyzer/services/l3_cli_runner.dart'
    show extractTargetMix;

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
    final stats = buildAutogenStats(jsonEncode(report))!;
    (report['autogen'] as Map<String, dynamic>)['stats'] = {
      'total': stats.total,
      'textures': stats.textures,
    };
    final outFile = File(outPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(jsonEncode(report));
    return;
  }
}
