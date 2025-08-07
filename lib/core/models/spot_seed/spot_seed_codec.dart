import 'dart:convert';

import 'package:json2yaml/json2yaml.dart';
import 'package:yaml/yaml.dart';

import 'unified_spot_seed_format.dart';

/// Codec for converting [SpotSeed] to and from JSON/YAML.
class SpotSeedCodec {
  const SpotSeedCodec();

  /// Decode a [SpotSeed] from a JSON [Map].
  SpotSeed fromJson(Map<String, dynamic> json) {
    return SpotSeed(
      id: json['id'] as String,
      gameType: json['gameType'] as String,
      bb: (json['bb'] as num).toDouble(),
      stackBB: (json['stackBB'] as num).toDouble(),
      positions: SpotPositions(
        hero: json['positions']['hero'] as String,
        villain: json['positions']['villain'] as String?,
      ),
      ranges: SpotRanges(
        hero: json['ranges']?['hero'] as String?,
        villain: json['ranges']?['villain'] as String?,
      ),
      board: SpotBoard(
        preflop: (json['board']?['preflop'] as List?)?.cast<String>(),
        flop: (json['board']?['flop'] as List?)?.cast<String>(),
        turn: (json['board']?['turn'] as List?)?.cast<String>(),
        river: (json['board']?['river'] as List?)?.cast<String>(),
      ),
      pot: (json['pot'] as num).toDouble(),
      icm: json['icm'] != null
          ? SpotIcm(
              stackDistribution: (json['icm']['stackDistribution'] as List?)
                  ?.map((e) => (e as num).toDouble())
                  .toList(),
              payouts: (json['icm']['payouts'] as List?)
                  ?.map((e) => (e as num).toDouble())
                  .toList(),
            )
          : null,
      tags: (json['tags'] as List?)?.cast<String>(),
      difficulty: json['difficulty'] as String?,
      audience: json['audience'] as String?,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
    );
  }

  /// Encode a [SpotSeed] to JSON.
  Map<String, dynamic> toJson(SpotSeed seed) {
    final map = <String, dynamic>{
      'id': seed.id,
      'gameType': seed.gameType,
      'bb': seed.bb,
      'stackBB': seed.stackBB,
      'positions': {
        'hero': seed.positions.hero,
        if (seed.positions.villain != null) 'villain': seed.positions.villain,
      },
      'ranges': {
        if (seed.ranges.hero != null) 'hero': seed.ranges.hero,
        if (seed.ranges.villain != null) 'villain': seed.ranges.villain,
      },
      'board': {
        if (seed.board.preflop != null) 'preflop': seed.board.preflop,
        if (seed.board.flop != null) 'flop': seed.board.flop,
        if (seed.board.turn != null) 'turn': seed.board.turn,
        if (seed.board.river != null) 'river': seed.board.river,
      },
      'pot': seed.pot,
    };

    if (seed.icm != null) {
      map['icm'] = {
        if (seed.icm!.stackDistribution != null)
          'stackDistribution': seed.icm!.stackDistribution,
        if (seed.icm!.payouts != null) 'payouts': seed.icm!.payouts,
      };
    }

    if (seed.tags.isNotEmpty) {
      map['tags'] = seed.tags;
    }
    if (seed.difficulty != null) {
      map['difficulty'] = seed.difficulty;
    }
    if (seed.audience != null) {
      map['audience'] = seed.audience;
    }
    if (seed.meta.isNotEmpty) {
      map['meta'] = seed.meta;
    }
    return map;
  }

  /// Decode from a YAML [String].
  SpotSeed fromYaml(String yaml) {
    final dynamic doc = loadYaml(yaml);
    final json = jsonDecode(jsonEncode(doc)) as Map<String, dynamic>;
    return fromJson(json);
  }

  /// Encode [seed] to a YAML [String].
  String toYaml(SpotSeed seed) {
    final json = toJson(seed);
    return json2yaml(json);
  }
}
