import 'dart:convert';

import 'open_fold_generator.dart';

class SpotDTO {
  final String hand;
  final String pos;
  final String stack;
  final String action;
  const SpotDTO({
    required this.hand,
    required this.pos,
    required this.stack,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
    'hand': hand,
    'pos': pos,
    'stack': stack,
    'action': action,
  };
}

class SpotPack {
  final String version;
  final int seed;
  final int count;
  final L2Mix mix;
  final List<SpotDTO> items;
  const SpotPack({
    required this.version,
    required this.seed,
    required this.count,
    required this.mix,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'seed': seed,
    'count': count,
    'mix': {
      'posPct': {for (final e in mix.posPct.entries) e.key.name: e.value},
      'stackPct': {for (final e in mix.stackPct.entries) e.key.name: e.value},
    },
    'items': [for (final i in items) i.toJson()],
  };
}

SpotPack buildOpenFoldPack({
  required int seed,
  required int count,
  required L2Mix mix,
}) {
  final spots = generateOpenFoldSpots(seed: seed, count: count, mix: mix);
  return SpotPack(
    version: 'v1',
    seed: seed,
    count: count,
    mix: mix,
    items: [
      for (final s in spots)
        SpotDTO(
          hand: s.hand,
          pos: s.pos.name,
          stack: s.stack.name,
          action: s.action.name,
        ),
    ],
  );
}

String encodeSpotPackCompact(SpotPack pack) => jsonEncode(pack.toJson());

String encodeSpotPackPretty(SpotPack pack) =>
    const JsonEncoder.withIndent('  ').convert(pack.toJson());
