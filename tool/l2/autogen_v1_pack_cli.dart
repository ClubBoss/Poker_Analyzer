import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/l2/autogen_v1/spot_pack.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('seed', help: 'required seed')
    ..addOption('count', defaultsTo: '40')
    ..addOption('preset', defaultsTo: 'mvs')
    ..addOption('format',
        defaultsTo: 'compact', allowed: ['compact', 'pretty']);
  ArgResults opts;
  try {
    opts = parser.parse(args);
  } catch (_) {
    _usage();
    exit(2);
  }
  final seedStr = opts['seed'];
  if (seedStr == null) {
    _usage();
    exit(2);
  }
  final seed = int.tryParse(seedStr);
  final count = int.tryParse(opts['count'] ?? '');
  if (seed == null || count == null) {
    _usage();
    exit(2);
  }
  final preset = opts['preset'];
  final format = opts['format'];
  L2Mix mix;
  switch (preset) {
    case 'mvs':
      mix = L2Mix.mvsDefault();
      break;
    default:
      _usage();
      exit(2);
  }
  final pack = buildOpenFoldPack(seed: seed, count: count, mix: mix);
  final json = format == 'pretty'
      ? encodeSpotPackPretty(pack)
      : encodeSpotPackCompact(pack);
  stdout.write(json);
}

void _usage() {
  stderr.writeln(
      'Usage: dart run tool/l2/autogen_v1_pack_cli.dart --seed <int> [--count <int>] [--preset mvs] [--format compact|pretty]');
}
