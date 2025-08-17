import 'dart:math';

/// Player positions for limped spots.
enum Pos { utg, mp, co, btn, sb, bb }

/// Stack size buckets in big blinds.
enum StackBin { bb5, bb10, bb15, bb20 }

/// Number of limpers before hero.
enum Limpers { one, multi }

/// Available actions for limped spots.
enum LimpAction { iso, overlimp, fold }

/// Immutable limped spot description.
class LimpSpot {
  final String hand;
  final Pos pos;
  final StackBin stack;
  final Limpers limpers;
  final LimpAction action;
  const LimpSpot({
    required this.hand,
    required this.pos,
    required this.stack,
    required this.limpers,
    required this.action,
  });

  @override
  bool operator ==(Object other) {
    return other is LimpSpot &&
        other.hand == hand &&
        other.pos == pos &&
        other.stack == stack &&
        other.limpers == limpers &&
        other.action == action;
  }

  @override
  int get hashCode => Object.hash(hand, pos, stack, limpers, action);

  @override
  String toString() =>
      '$hand ${pos.name} ${stack.name} ${limpers.name} ${action.name}';
}

/// Mix configuration for generation.
class L2LimpMix {
  final Map<Pos, double> posPct;
  final Map<StackBin, double> stackPct;
  final Map<Limpers, double> limpersPct;
  const L2LimpMix({
    required this.posPct,
    required this.stackPct,
    required this.limpersPct,
  });

  static const L2LimpMix _mvs = L2LimpMix(
    posPct: {
      Pos.utg: 0.10,
      Pos.mp: 0.20,
      Pos.co: 0.25,
      Pos.btn: 0.25,
      Pos.sb: 0.10,
      Pos.bb: 0.10,
    },
    stackPct: {
      StackBin.bb5: 0.25,
      StackBin.bb10: 0.25,
      StackBin.bb15: 0.25,
      StackBin.bb20: 0.25,
    },
    limpersPct: {
      Limpers.one: 0.60,
      Limpers.multi: 0.40,
    },
  );

  static L2LimpMix mvsDefault() => _mvs;
}

const _handPool = [
  'AA',
  'KK',
  'QQ',
  'JJ',
  'TT',
  '99',
  '88',
  '77',
  'AKs',
  'AQs',
  'AJs',
  'ATs',
  'KQs',
  'KJs',
  'QJs',
  'JTs',
  'T9s',
  '98s',
  '87s',
  'AJo',
  'KQo',
  'QJo',
  'A9s',
  'KTs',
  'A5s',
  '76s',
  '65s',
  '22',
  '33',
  '44',
  '55',
  'A4s',
  'A3s',
  'A2s',
];

const _isoHands = {
  'AJo',
  'KQo',
  'KJs',
  'KQs',
  'QJs',
  'TT',
  'JJ',
  'QQ',
  'KK',
  'AA',
  'A5s',
  'KTs',
};

const _overlimpHands = {
  '22',
  '33',
  '44',
  '55',
  '66',
  '77',
  '88',
  '99',
  'T9s',
  '98s',
  '87s',
  '76s',
  '65s',
  'A9s',
  'A8s',
  'A7s',
  'A6s',
  'A5s',
  'A4s',
  'A3s',
  'A2s',
  'KTs',
  'QTs',
  'JTs',
};

List<LimpSpot> generateLimpSpots({
  required int seed,
  required int count,
  required L2LimpMix mix,
}) {
  final rand = Random(seed);
  final items = <LimpSpot>[];
  final used = <String>{};

  final posQuota = _buildQuotas(mix.posPct, count, Pos.values);
  final stackQuota = _buildQuotas(mix.stackPct, count, StackBin.values);
  final limpQuota = _buildQuotas(mix.limpersPct, count, Limpers.values);

  while (items.length < count && used.length < 100000) {
    final hand = _handPool[rand.nextInt(_handPool.length)];
    final pos = _pickWithQuota(rand, posQuota, Pos.values);
    final stack = _pickWithQuota(rand, stackQuota, StackBin.values);
    final limpers = _pickWithQuota(rand, limpQuota, Limpers.values);
    final key = '$hand|${pos.name}|${stack.name}|${limpers.name}';
    if (used.contains(key)) continue;
    final action = _decide(hand, pos, limpers);
    items.add(LimpSpot(
      hand: hand,
      pos: pos,
      stack: stack,
      limpers: limpers,
      action: action,
    ));
    used.add(key);
  }

  return items;
}

LimpAction _decide(String hand, Pos pos, Limpers limpers) {
  if ({Pos.co, Pos.btn, Pos.sb}.contains(pos) && _isoHands.contains(hand)) {
    return LimpAction.iso;
  }
  if (limpers == Limpers.multi && _overlimpHands.contains(hand)) {
    return LimpAction.overlimp;
  }
  return LimpAction.fold;
}

Map<T, int> _buildQuotas<T>(Map<T, double> pct, int total, List<T> order) {
  final quotas = <T, int>{};
  var remaining = total;
  for (var i = 0; i < order.length; i++) {
    final v = order[i];
    final q =
        i == order.length - 1 ? remaining : (total * (pct[v] ?? 0)).round();
    quotas[v] = q;
    remaining -= q;
  }
  return quotas;
}

T _pickWithQuota<T>(Random rand, Map<T, int> quota, List<T> order) {
  var choice = order[rand.nextInt(order.length)];
  if ((quota[choice] ?? 0) > 0) {
    quota[choice] = quota[choice]! - 1;
    return choice;
  }
  for (final v in order) {
    if ((quota[v] ?? 0) > 0) {
      quota[v] = quota[v]! - 1;
      return v;
    }
  }
  return order.first;
}
