import 'dart:convert';

import 'limped_response_generator.dart';

class LimpDTO {
  final String hand;
  final String pos;
  final String stack;
  final String limpers;
  final String action;
  const LimpDTO({
    required this.hand,
    required this.pos,
    required this.stack,
    required this.limpers,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
        'hand': hand,
        'pos': pos,
        'stack': stack,
        'limpers': limpers,
        'action': action,
      };
}

class LimpPack {
  final String version;
  final int seed;
  final int count;
  final L2LimpMix mix;
  final List<LimpDTO> items;
  const LimpPack({
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
          'posPct': {
            for (final e in mix.posPct.entries) e.key.name: e.value,
          },
          'stackPct': {
            for (final e in mix.stackPct.entries) e.key.name: e.value,
          },
          'limpersPct': {
            for (final e in mix.limpersPct.entries) e.key.name: e.value,
          },
        },
        'items': [for (final i in items) i.toJson()],
      };
}

LimpPack buildLimpPack({
  required int seed,
  required int count,
  required L2LimpMix mix,
}) {
  final spots = generateLimpSpots(seed: seed, count: count, mix: mix);
  return LimpPack(
    version: 'v1',
    seed: seed,
    count: count,
    mix: mix,
    items: [
      for (final s in spots)
        LimpDTO(
          hand: s.hand,
          pos: s.pos.name,
          stack: s.stack.name,
          limpers: s.limpers.name,
          action: s.action.name,
        )
    ],
  );
}

String encodeLimpPackCompact(LimpPack pack) => jsonEncode(pack.toJson());

String encodeLimpPackPretty(LimpPack pack) =>
    const JsonEncoder.withIndent('  ').convert(pack.toJson());
