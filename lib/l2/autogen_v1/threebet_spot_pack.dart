import 'dart:convert';

import 'threebet_push_generator.dart';

class TbDTO {
  final String hand;
  final String heroPos;
  final String vsPos;
  final String stack;
  final String action;
  const TbDTO({
    required this.hand,
    required this.heroPos,
    required this.vsPos,
    required this.stack,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
    'hand': hand,
    'heroPos': heroPos,
    'vsPos': vsPos,
    'stack': stack,
    'action': action,
  };
}

class TbPack {
  final String version;
  final int seed;
  final int count;
  final L2TbMix mix;
  final List<TbDTO> items;
  const TbPack({
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
      'heroPosPct': {
        for (final e in mix.heroPosPct.entries) e.key.name: e.value,
      },
      'vsPosPct': {for (final e in mix.vsPosPct.entries) e.key.name: e.value},
      'stackPct': {for (final e in mix.stackPct.entries) e.key.name: e.value},
    },
    'items': [for (final i in items) i.toJson()],
  };
}

TbPack buildThreebetPack({
  required int seed,
  required int count,
  required L2TbMix mix,
}) {
  final spots = generateThreebetSpots(seed: seed, count: count, mix: mix);
  return TbPack(
    version: 'v1',
    seed: seed,
    count: count,
    mix: mix,
    items: [
      for (final s in spots)
        TbDTO(
          hand: s.hand,
          heroPos: s.heroPos.name,
          vsPos: s.vsPos.name,
          stack: s.stack.name,
          action: s.action.name,
        ),
    ],
  );
}

String encodeTbPackCompact(TbPack pack) => jsonEncode(pack.toJson());

String encodeTbPackPretty(TbPack pack) =>
    const JsonEncoder.withIndent('  ').convert(pack.toJson());
