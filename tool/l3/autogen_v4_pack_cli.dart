import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/l3/autogen_v4/board_street_generator.dart';
import 'package:poker_analyzer/l3/autogen_v4/spot_pack.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('seed')
    ..addOption('count', defaultsTo: '40')
    ..addOption('preset', defaultsTo: 'mvs')
    ..addOption('format', defaultsTo: 'compact');

  ArgResults res;
  try {
    res = parser.parse(args);
  } catch (_) {
    _usage();
    exit(2);
  }

  final seedStr = res['seed'] as String?;
  final countStr = res['count'] as String?;
  final preset = res['preset'] as String?;
  final format = res['format'] as String?;

  final seed = int.tryParse(seedStr ?? '');
  final count = int.tryParse(countStr ?? '40');
  if (seed == null || count == null || preset != 'mvs' ||
      (format != 'compact' && format != 'pretty')) {
    _usage();
    exit(2);
  }

  const mix = TargetMix.mvsDefault();
  final pack = buildSpotPack(seed: seed, count: count, mix: mix);
  final out = format == 'pretty'
      ? encodeSpotPackPretty(pack)
      : encodeSpotPackCompact(pack);
  stdout.write(out);
}

void _usage() {
  stdout.writeln(
      'usage: --seed=<int> [--count=<int>] [--preset=mvs] [--format=compact|pretty]');
}
