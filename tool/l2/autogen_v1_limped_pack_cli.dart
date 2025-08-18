import 'dart:io';

import 'package:poker_analyzer/l2/autogen_v1/limped_spot_pack.dart';

void main(List<String> args) {
  final opts = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    var a = args[i];
    if (a.startsWith('--')) {
      a = a.substring(2);
      final eq = a.indexOf('=');
      if (eq != -1) {
        opts[a.substring(0, eq)] = a.substring(eq + 1);
      } else if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        opts[a] = args[++i];
      } else {
        opts[a] = 'true';
      }
    }
  }

  final seedStr = opts['seed'];
  final countStr = opts['count'] ?? '40';
  final preset = opts['preset'] ?? 'mvs';
  final format = opts['format'] ?? 'compact';

  final seed = seedStr != null ? int.tryParse(seedStr) : null;
  final count = int.tryParse(countStr);
  if (seed == null ||
      count == null ||
      preset != 'mvs' ||
      (format != 'compact' && format != 'pretty')) {
    _usage();
    exit(2);
  }

  final mix = L2LimpMix.mvsDefault();
  final pack = buildLimpPack(seed: seed, count: count, mix: mix);
  final json = format == 'pretty'
      ? encodeLimpPackPretty(pack)
      : encodeLimpPackCompact(pack);
  stdout.write(json);
}

void _usage() {
  stderr.writeln(
    'Usage: dart run tool/l2/autogen_v1_limped_pack_cli.dart --seed <int> [--count <int>] [--preset mvs] [--format compact|pretty]',
  );
}
