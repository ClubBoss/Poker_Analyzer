import 'dart:io';

import 'package:poker_analyzer/l2/autogen_v1/open_fold_generator.dart';
import 'package:poker_analyzer/l2/autogen_v1/threebet_push_generator.dart';
import 'package:poker_analyzer/l2/autogen_v1/limped_response_generator.dart';
import 'package:poker_analyzer/l2/autogen_v1/session_manifest.dart';

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
  final perKindStr = opts['per-kind'] ?? '20';
  final kindsStr = opts['kinds'] ?? 'open_fold,threebet_push,limped';
  final format = opts['format'] ?? 'compact';
  final outDir = opts['out'] ?? 'out/l2_sessions';
  var name = opts['name'];

  final seed = seedStr != null ? int.tryParse(seedStr) : null;
  final perKind = int.tryParse(perKindStr);
  final kinds = kindsStr.split(',').where((e) => e.isNotEmpty).toList();
  const allowedKinds = {'open_fold', 'threebet_push', 'limped'};

  if (seed == null ||
      perKind == null ||
      perKind <= 0 ||
      kinds.isEmpty ||
      kinds.any((k) => !allowedKinds.contains(k)) ||
      (format != 'compact' && format != 'pretty')) {
    _usage();
    exit(2);
  }

  name ??= 'session_l2_v1_seed${seed}_k${perKind}.json';

  final items = <L2SessionItem>[];
  final sOf = seed + 1;
  final sTb = seed + 2;
  final sLimp = seed + 3;

  for (final k in kinds) {
    switch (k) {
      case 'open_fold':
        final spots = generateOpenFoldSpots(
          seed: sOf,
          count: perKind,
          mix: L2Mix.mvsDefault(),
        );
        for (final s in spots) {
          items.add(
            L2SessionItem(
              kind: 'open_fold',
              hand: s.hand,
              pos: s.pos.name,
              stack: s.stack.name,
              action: s.action.name,
            ),
          );
        }
        break;
      case 'threebet_push':
        final spots = generateThreebetSpots(
          seed: sTb,
          count: perKind,
          mix: L2TbMix.mvsDefault(),
        );
        for (final s in spots) {
          items.add(
            L2SessionItem(
              kind: 'threebet_push',
              hand: s.hand,
              pos: s.heroPos.name,
              stack: s.stack.name,
              action: s.action.name,
              vsPos: s.vsPos.name,
            ),
          );
        }
        break;
      case 'limped':
        final spots = generateLimpSpots(
          seed: sLimp,
          count: perKind,
          mix: L2LimpMix.mvsDefault(),
        );
        for (final s in spots) {
          items.add(
            L2SessionItem(
              kind: 'limped',
              hand: s.hand,
              pos: s.pos.name,
              stack: s.stack.name,
              action: s.action.name,
              limpers: s.limpers.name,
            ),
          );
        }
        break;
    }
  }

  final manifest = L2SessionManifest(
    version: 'v1',
    baseSeed: seed,
    perKind: perKind,
    kinds: kinds,
    items: items,
  );

  final json = format == 'pretty'
      ? encodeL2ManifestPretty(manifest)
      : encodeL2ManifestCompact(manifest);

  final dir = Directory(outDir);
  dir.createSync(recursive: true);
  final file = File('${dir.path}/$name');
  file.writeAsStringSync(json);

  final total = items.length;
  stdout.writeln(
    'wrote L2 session name=$name kinds=${kinds.join(',')} perKind=$perKind total=$total seed=$seed format=$format',
  );
}

void _usage() {
  stderr.writeln(
    'usage: --seed N [--per-kind N] [--kinds open_fold,threebet_push,limped] [--format compact|pretty] [--out dir] [--name file]',
  );
}
