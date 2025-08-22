import 'dart:io';

import 'package:poker_analyzer/l4/icm_v1/jam_generator.dart';
import 'package:poker_analyzer/l4/icm_v1/session_manifest.dart';

void main(List<String> args) {
  List<int>? seeds;
  String? rangeArg;
  var perSeed = 20;
  var preset = 'mvs';
  var format = 'compact';
  var outDir = 'out/l4_sessions';
  String? name;

  for (final a in args) {
    if (a.startsWith('--seeds=')) {
      final s = a.substring(8);
      if (s.isNotEmpty) {
        seeds = s.split(',').where((e) => e.isNotEmpty).map(int.parse).toList();
      } else {
        seeds = <int>[];
      }
    } else if (a.startsWith('--range=')) {
      rangeArg = a.substring(8);
    } else if (a.startsWith('--per-seed=')) {
      perSeed = int.tryParse(a.substring(11)) ?? perSeed;
    } else if (a.startsWith('--preset=')) {
      preset = a.substring(9);
    } else if (a.startsWith('--format=')) {
      format = a.substring(9);
    } else if (a.startsWith('--out=')) {
      outDir = a.substring(6);
    } else if (a.startsWith('--name=')) {
      name = a.substring(7);
    } else {
      _usage();
      exit(2);
    }
  }

  if (seeds != null && rangeArg != null) {
    _usage();
    exit(2);
  }
  if (seeds == null && rangeArg == null) {
    _usage();
    exit(2);
  }
  if (rangeArg != null) {
    final parts = rangeArg.split('-');
    if (parts.length != 2) {
      _usage();
      exit(2);
    }
    final start = int.tryParse(parts[0]);
    final end = int.tryParse(parts[1]);
    if (start == null || end == null || end < start) {
      _usage();
      exit(2);
    }
    seeds = [for (var s = start; s <= end; s++) s];
  }

  if (perSeed <= 0) {
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
  final items = <L4IcmSessionItem>[];
  for (final seed in seeds!) {
    final spots = generateIcmJamSpots(seed: seed, count: perSeed, mix: mix);
    for (final s in spots) {
      items.add(
        L4IcmSessionItem(
          hand: s.hand,
          heroPos: s.heroPos.name,
          stackBb: s.stackBb.name,
          stacks: s.stacks.name,
          action: s.action.name,
        ),
      );
    }
  }

  final manifest = L4IcmSessionManifest(
    preset: 'mvs',
    total: items.length,
    seeds: seeds,
    perSeed: perSeed,
    items: items,
  );

  final json = format == 'pretty'
      ? encodeIcmManifestPretty(manifest)
      : encodeIcmManifestCompact(manifest);

  final dir = Directory(outDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final k = seeds.length;
  name ??= 'session_icm_v1_\${preset}_k\${k}_n\${perSeed}.json';
  final file = File('${dir.path}/$name');
  file.writeAsStringSync(json);

  stdout.writeln(
    'wrote L4 ICM session name=$name seeds=$k perSeed=$perSeed total=${items.length} format=$format',
  );
}

void _usage() {
  stderr.writeln(
    'usage: --seeds a,b,c | --range start-end [--per-seed N] [--preset mvs] [--format compact|pretty] [--out dir] [--name file]',
  );
}
