import 'dart:math';

/// Street selection for a spot.
enum Street { flop, turn, river }

/// Stack-to-pot ratio bins.
enum SprBin { short, mid, deep }

/// Player position.
enum Position { ip, oop }

/// Immutable minimal spot description.
class Spot {
  final String board;
  final Street street;
  final SprBin sprBin;
  final Position pos;

  const Spot({
    required this.board,
    required this.street,
    required this.sprBin,
    required this.pos,
  });

  @override
  String toString() => '$board ${pos.name} ${sprBin.name} ${street.name}';

  @override
  bool operator ==(Object other) =>
      other is Spot &&
      other.board == board &&
      other.street == street &&
      other.sprBin == sprBin &&
      other.pos == pos;

  @override
  int get hashCode => Object.hash(board, street, sprBin, pos);
}

/// Target mix configuration for generation.
class TargetMix {
  final Map<Street, double> streetPct;
  final Map<SprBin, double> sprPct;
  final Map<Position, double> posPct;

  const TargetMix({
    required this.streetPct,
    required this.sprPct,
    required this.posPct,
  });

  /// Const named constructor so callers can do: `const mix = TargetMix.mvsDefault();`
  const TargetMix.mvsDefault()
      : streetPct = const {
          Street.flop: 0.5,
          Street.turn: 0.3,
          Street.river: 0.2,
        },
        sprPct = const {
          SprBin.short: 0.4,
          SprBin.mid: 0.4,
          SprBin.deep: 0.2,
        },
        posPct = const {
          Position.ip: 0.5,
          Position.oop: 0.5,
        };
}

const List<String> _flopTextures = [
  'A72r',
  'KQTr',
  'T98hh',
  '553r',
  'J74hh',
  'Q82r',
  '742r',
  'AATr',
  '998r',
  'K72hh',
  'T84r',
  '876r',
  '972hh',
  '433r',
  'QJ9hh',
  'K85r',
  '964r',
  'T73r',
  'J65r',
  'A98r',
  'KQ9hh',
  'TT9r',
  'AK2hh',
  '983r',
];

const List<String> _turnRanks = [
  'A',
  'K',
  'Q',
  'J',
  'T',
  '9',
  '8',
  '7',
  '6',
  '5',
  '4',
  '3',
  '2'
];

const List<String> _riverRanks = _turnRanks;

/// Generate a list of [Spot]s using minimal variables setup.
List<Spot> generateSpots({
  required int seed,
  required int count,
  required TargetMix mix,
}) {
  final rng = Random(seed);
  final streetQuota = _computeQuotas(mix.streetPct, count);
  final sprQuota = _computeQuotas(mix.sprPct, count);
  final posQuota = _computeQuotas(mix.posPct, count);

  final spots = <Spot>[];
  final used = <String>{};

  while (spots.length < count) {
    final street = _pickWithQuota(rng, Street.values, streetQuota);
    final spr = _pickWithQuota(rng, SprBin.values, sprQuota);
    final pos = _pickWithQuota(rng, Position.values, posQuota);

    var board = _buildBoard(rng, street);
    var key = '$board-${pos.name}-${spr.name}';
    var attempts = 0;
    while (used.contains(key) && attempts < 5) {
      board = _buildBoard(rng, street);
      key = '$board-${pos.name}-${spr.name}';
      attempts++;
    }
    if (used.contains(key)) {
      continue; // collision, retry
    }

    spots.add(Spot(board: board, street: street, sprBin: spr, pos: pos));
    used.add(key);

    streetQuota[street] = streetQuota[street]! - 1;
    sprQuota[spr] = sprQuota[spr]! - 1;
    posQuota[pos] = posQuota[pos]! - 1;
  }

  return spots;
}

T _pickWithQuota<T>(Random rng, List<T> values, Map<T, int> quota) {
  final remaining = <T>[];
  var total = 0;
  for (final v in values) {
    final q = quota[v] ?? 0;
    if (q > 0) {
      remaining.add(v);
      total += q;
    }
  }
  if (total == 0) return values.first;
  var roll = rng.nextInt(total);
  for (final v in remaining) {
    final q = quota[v]!;
    if (roll < q) return v;
    roll -= q;
  }
  return remaining.last;
}

Map<T, int> _computeQuotas<T>(Map<T, double> pct, int count) {
  final quotas = <T, int>{};
  final fractions = <T, double>{};
  var total = 0;
  pct.forEach((key, value) {
    final exact = value * count;
    final q = exact.floor();
    quotas[key] = q;
    fractions[key] = exact - q;
    total += q;
  });
  final keys = fractions.keys.toList()
    ..sort((a, b) => fractions[b]!.compareTo(fractions[a]!));
  var idx = 0;
  while (total < count) {
    final k = keys[idx % keys.length];
    quotas[k] = quotas[k]! + 1;
    total++;
    idx++;
  }
  return quotas;
}

String _buildBoard(Random rng, Street street) {
  final flop = _flopTextures[rng.nextInt(_flopTextures.length)];
  if (street == Street.flop) return flop;
  final turn = _turnRanks[rng.nextInt(_turnRanks.length)];
  if (street == Street.turn) return '$flop|$turn';
  final river = _riverRanks[rng.nextInt(_riverRanks.length)];
  return '$flop|$turn|$river';
}

int _fnv1a32(String input) {
  const int prime = 0x01000193;
  int hash = 0x811c9dc5;
  for (final c in input.codeUnits) {
    hash ^= c;
    hash = (hash * prime) & 0xFFFFFFFF;
  }
  return hash;
}

/// Concatenate the first [n] [Spot]s' `toString()` and hash them.
String itemsHash(List<Spot> items, int n) {
  final buffer = StringBuffer();
  for (var i = 0; i < n && i < items.length; i++) {
    buffer.write(items[i].toString());
  }
  final h = _fnv1a32(buffer.toString());
  return h.toRadixString(16).padLeft(8, '0');
}
