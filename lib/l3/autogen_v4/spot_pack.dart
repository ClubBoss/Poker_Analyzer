// Minimal deterministic JSON pack structures for L3 spots.
import 'dart:convert';

import 'board_street_generator.dart';

class SpotDTO {
  final String board;
  final String street;
  final String spr;
  final String pos;

  const SpotDTO({
    required this.board,
    required this.street,
    required this.spr,
    required this.pos,
  });

  factory SpotDTO.fromSpot(Spot s) => SpotDTO(
    board: s.board,
    street: s.street.name,
    spr: s.sprBin.name,
    pos: s.pos.name,
  );

  Map<String, String> toJson() => {
    'board': board,
    'street': street,
    'spr': spr,
    'pos': pos,
  };
}

class SpotPack {
  final String version;
  final int seed;
  final int count;
  final TargetMix mix;
  final List<SpotDTO> items;

  const SpotPack({
    this.version = 'v1',
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
      'streetPct': _enumMapToJson(Street.values, mix.streetPct),
      'sprPct': _enumMapToJson(SprBin.values, mix.sprPct),
      'posPct': _enumMapToJson(Position.values, mix.posPct),
    },
    'items': items.map((e) => e.toJson()).toList(),
  };
}

Map<String, double> _enumMapToJson<E>(List<E> order, Map<E, double> src) {
  final out = <String, double>{};
  for (final e in order) {
    final v = src[e];
    if (v != null) {
      out[(e as dynamic).name as String] = v;
    }
  }
  return out;
}

SpotPack buildSpotPack({
  required int seed,
  required int count,
  required TargetMix mix,
}) {
  final spots = generateSpots(seed: seed, count: count, mix: mix);
  final items = spots.map(SpotDTO.fromSpot).toList();
  return SpotPack(seed: seed, count: count, mix: mix, items: items);
}

String encodeSpotPackCompact(SpotPack p) => jsonEncode(p.toJson());

String encodeSpotPackPretty(SpotPack p) =>
    const JsonEncoder.withIndent(' ').convert(p.toJson());
