import 'dart:io';

import 'package:poker_analyzer/l4/icm_v1/spot_pack.dart';

void main(List<String> args) {
  int? seed;
  var count = 40;
  var preset = 'mvs';
  var format = 'compact';
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    switch (a) {
      case '--seed':
        if (i + 1 < args.length) seed = int.tryParse(args[++i]);
        break;
      case '--count':
        if (i + 1 < args.length) count = int.tryParse(args[++i]) ?? count;
        break;
      case '--preset':
        if (i + 1 < args.length) preset = args[++i];
        break;
      case '--format':
        if (i + 1 < args.length) format = args[++i];
        break;
      default:
        _usage();
        exit(2);
    }
  }
  if (seed == null) {
    _usage();
    exit(2);
  }
  if (preset != 'mvs') {
    _usage();
    exit(2);
  }
  if (format != 'compact' && format != 'pretty') {
    _usage();
    exit(2);
  }
  final mix = IcmMix.mvsDefault();
  final pack = buildIcmPack(seed: seed!, count: count, mix: mix);
  final json =
      format == 'pretty' ? encodeIcmPackPretty(pack) : encodeIcmPackCompact(pack);
  stdout.write(json);
}

void _usage() {
  stderr.writeln(
      'Usage: dart run tool/l4/icm_v1_pack_cli.dart --seed <int> [--count <int>] [--preset mvs] [--format compact|pretty]');
}
