import 'dart:math';

import 'package:poker_analyzer/helpers/push_fold_helper.dart';
import 'package:poker_analyzer/utils/push_fold.dart' as pf;

/// Player positions for open/fold spots.
enum Pos { utg, mp, co, btn, sb, bb }

/// Stack size buckets in big blinds.
enum StackBin { bb5, bb10, bb15, bb20 }

/// Available actions for a spot.
enum Action { open, fold }

/// Immutable open/fold spot description.
class OpenFoldSpot {
  final String hand;
  final Pos pos;
  final StackBin stack;
  final Action action;
  const OpenFoldSpot({
    required this.hand,
    required this.pos,
    required this.stack,
    required this.action,
  });

  @override
  bool operator ==(Object other) {
    return other is OpenFoldSpot &&
        other.hand == hand &&
        other.pos == pos &&
        other.stack == stack &&
        other.action == action;
  }

  @override
  int get hashCode => Object.hash(hand, pos, stack, action);

  @override
  String toString() => '$hand ${pos.name} ${stack.name} ${action.name}';
}

/// Mix configuration for generation.
class L2Mix {
  final Map<Pos, double> posPct;
  final Map<StackBin, double> stackPct;
  const L2Mix({required this.posPct, required this.stackPct});

  static const L2Mix _mvs = L2Mix(
    posPct: {
      Pos.utg: 0.15,
      Pos.mp: 0.20,
      Pos.co: 0.20,
      Pos.btn: 0.20,
      Pos.sb: 0.125,
      Pos.bb: 0.125,
    },
    stackPct: {
      StackBin.bb5: 0.25,
      StackBin.bb10: 0.25,
      StackBin.bb15: 0.25,
      StackBin.bb20: 0.25,
    },
  );

  static L2Mix mvsDefault() => _mvs;
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
  'AJo',
  'KQo',
  'QJo',
  'A9s',
  'KTs',
  'A5s',
  '76s',
  '65s',
];

List<OpenFoldSpot> generateOpenFoldSpots({
  required int seed,
  required int count,
  required L2Mix mix,
}) {
  final rand = Random(seed);
  final items = <OpenFoldSpot>[];
  final used = <String>{};

  final posQuota = _buildQuotas(mix.posPct, count, Pos.values);
  final stackQuota = _buildQuotas(mix.stackPct, count, StackBin.values);

  while (items.length < count && used.length < 100000) {
    final hand = _handPool[rand.nextInt(_handPool.length)];
    final pos = _pickWithQuota(rand, posQuota, Pos.values);
    final stack = _pickWithQuota(rand, stackQuota, StackBin.values);
    final key = '$hand|${pos.name}|${stack.name}';
    if (used.contains(key)) continue;
    final action = PfAdapter.openOrFold(hand: hand, pos: pos, stack: stack);
    items.add(OpenFoldSpot(hand: hand, pos: pos, stack: stack, action: action));
    used.add(key);
  }

  return items;
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

class PfAdapter {
  static Action openOrFold({
    required String hand,
    required Pos pos,
    required StackBin stack,
  }) {
    final stackBb = _stackToInt(stack);
    final thr = kPushFoldThresholds[hand];
    if (thr != null && stackBb <= thr) {
      final norm = pf.normalizeAction('push');
      return norm == pf.kPushKey ? Action.open : Action.fold;
    }
    return Action.fold;
  }
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
