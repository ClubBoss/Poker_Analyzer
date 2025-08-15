// Minimal deterministic JSON pack structures for ICM jam spots.
import 'dart:convert';

import 'jam_generator.dart';

class IcmDTO {
  final String hand;
  final String heroPos;
  final String stackBb;
  final String stacks;
  final String action;

  const IcmDTO({
    required this.hand,
    required this.heroPos,
    required this.stackBb,
    required this.stacks,
    required this.action,
  });

  factory IcmDTO.fromSpot(IcmSpot s) => IcmDTO(
        hand: s.hand,
        heroPos: s.heroPos.name,
        stackBb: s.stackBb.name,
        stacks: s.stacks.name,
        action: s.action.name,
      );

  Map<String, String> toJson() => {
        'hand': hand,
        'heroPos': heroPos,
        'stackBb': stackBb,
        'stacks': stacks,
        'action': action,
      };
}

class IcmPack {
  final String version;
  final int seed;
  final int count;
  final IcmMix mix;
  final List<IcmDTO> items;

  const IcmPack({
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
          'posPct': _enumMapToJson(IcmPos.values, mix.posPct),
          'stackBbPct': _enumMapToJson(StackBin.values, mix.stackBbPct),
          'triplePct': _enumMapToJson(StackTriple.values, mix.triplePct),
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

IcmPack buildIcmPack({
  required int seed,
  required int count,
  required IcmMix mix,
}) {
  final spots = generateIcmJamSpots(seed: seed, count: count, mix: mix);
  final items = spots.map(IcmDTO.fromSpot).toList();
  return IcmPack(seed: seed, count: count, mix: mix, items: items);
}

String encodeIcmPackCompact(IcmPack p) => jsonEncode(p.toJson());

String encodeIcmPackPretty(IcmPack p) =>
    const JsonEncoder.withIndent(' ').convert(p.toJson());
