import 'dart:math';

import 'open_fold_generator.dart' show Pos, StackBin;
import 'package:poker_analyzer/helpers/push_fold_helper.dart';
import 'package:poker_analyzer/utils/push_fold.dart' as pf;

enum VsPos { utg, mp, co, btn }

enum TbAction { jam, fold }

class TbSpot {
  final String hand;
  final Pos heroPos;
  final VsPos vsPos;
  final StackBin stack;
  final TbAction action;
  const TbSpot({
    required this.hand,
    required this.heroPos,
    required this.vsPos,
    required this.stack,
    required this.action,
  });

  @override
  bool operator ==(Object other) {
    return other is TbSpot &&
        other.hand == hand &&
        other.heroPos == heroPos &&
        other.vsPos == vsPos &&
        other.stack == stack &&
        other.action == action;
  }

  @override
  int get hashCode => Object.hash(hand, heroPos, vsPos, stack, action);

  @override
  String toString() =>
      '$hand ${heroPos.name} vs ${vsPos.name} ${stack.name} ${action.name}';
}

class L2TbMix {
  final Map<Pos, double> heroPosPct;
  final Map<VsPos, double> vsPosPct;
  final Map<StackBin, double> stackPct;
  const L2TbMix({
    required this.heroPosPct,
    required this.vsPosPct,
    required this.stackPct,
  });

  static const L2TbMix _mvs = L2TbMix(
    heroPosPct: {Pos.co: 0.30, Pos.btn: 0.40, Pos.sb: 0.15, Pos.bb: 0.15},
    vsPosPct: {
      VsPos.utg: 0.20,
      VsPos.mp: 0.30,
      VsPos.co: 0.30,
      VsPos.btn: 0.20,
    },
    stackPct: {
      StackBin.bb5: 0.25,
      StackBin.bb10: 0.25,
      StackBin.bb15: 0.25,
      StackBin.bb20: 0.25,
    },
  );

  static L2TbMix mvsDefault() => _mvs;
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
];

List<TbSpot> generateThreebetSpots({
  required int seed,
  required int count,
  required L2TbMix mix,
}) {
  final rand = Random(seed);
  final items = <TbSpot>[];
  final used = <String>{};

  final heroQuota = _buildQuotas(mix.heroPosPct, count, Pos.values);
  final vsQuota = _buildQuotas(mix.vsPosPct, count, VsPos.values);
  final stackQuota = _buildQuotas(mix.stackPct, count, StackBin.values);

  while (items.length < count && used.length < 100000) {
    final hand = _handPool[rand.nextInt(_handPool.length)];
    final heroPos = _pickWithQuota(rand, heroQuota, Pos.values);
    final vsPos = _pickWithQuota(rand, vsQuota, VsPos.values);
    if (!_valid(heroPos, vsPos)) {
      heroQuota[heroPos] = (heroQuota[heroPos] ?? 0) + 1;
      vsQuota[vsPos] = (vsQuota[vsPos] ?? 0) + 1;
      continue;
    }
    final stack = _pickWithQuota(rand, stackQuota, StackBin.values);
    final key = '$hand|${heroPos.name}|${vsPos.name}|${stack.name}';
    if (used.contains(key)) continue;
    final action = Pf3betAdapter.jamOrFold(
      hand: hand,
      heroPos: heroPos,
      vsPos: vsPos,
      stack: stack,
    );
    items.add(
      TbSpot(
        hand: hand,
        heroPos: heroPos,
        vsPos: vsPos,
        stack: stack,
        action: action,
      ),
    );
    used.add(key);
  }

  return items;
}

bool _valid(Pos hero, VsPos vs) {
  switch (vs) {
    case VsPos.utg:
      return hero.index > Pos.utg.index;
    case VsPos.mp:
      return hero.index > Pos.mp.index;
    case VsPos.co:
      return hero.index > Pos.co.index;
    case VsPos.btn:
      return hero.index > Pos.btn.index;
  }
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

class Pf3betAdapter {
  static TbAction jamOrFold({
    required String hand,
    required Pos heroPos,
    required VsPos vsPos,
    required StackBin stack,
  }) {
    final base = kPushFoldThresholds[hand];
    if (base == null) return TbAction.fold;
    final stackBb = _stackToInt(stack);
    final adj = _adjust(base, vsPos);
    if (stackBb <= adj) {
      final norm = pf.normalizeAction('jam');
      return norm == pf.kPushKey ? TbAction.jam : TbAction.fold;
    }
    return TbAction.fold;
  }
}

int _adjust(int base, VsPos vsPos) {
  final adj = () {
    switch (vsPos) {
      case VsPos.utg:
        return base - 10;
      case VsPos.mp:
        return base - 5;
      case VsPos.co:
        return base;
      case VsPos.btn:
        return base + 5;
    }
  }();
  if (adj < 0) return 0;
  if (adj > 20) return 20;
  return adj;
}

int _stackToInt(StackBin s) {
  switch (s) {
    case StackBin.bb5:
      return 5;
    case StackBin.bb10:
      return 10;
    case StackBin.bb15:
      return 15;
    case StackBin.bb20:
      return 20;
  }
}
