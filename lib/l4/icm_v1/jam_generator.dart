import 'dart:math';

import 'package:poker_analyzer/helpers/push_fold_helper.dart';
import 'package:poker_analyzer/services/hand_range_library.dart';

/// ICM spot representation.
class IcmSpot {
  final String hand;
  final IcmPos heroPos;
  final StackTriple stacks;
  final StackBin stackBb;
  final IcmAction action;

  const IcmSpot({
    required this.hand,
    required this.heroPos,
    required this.stacks,
    required this.stackBb,
    required this.action,
  });

  @override
  String toString() =>
      '$hand ${heroPos.name} ${stackBb.name} ${stacks.name} ${action.name}';
}

enum IcmPos { btn, sb }

enum StackTriple { sss, sms, mms, mls, lms, lls }

enum StackBin { bb5, bb10, bb15 }

enum IcmAction { jam, fold }

class IcmMix {
  final Map<IcmPos, double> posPct;
  final Map<StackBin, double> stackBbPct;
  final Map<StackTriple, double> triplePct;

  const IcmMix({
    required this.posPct,
    required this.stackBbPct,
    required this.triplePct,
  });

  factory IcmMix.mvsDefault() => const IcmMix(
        posPct: {IcmPos.btn: 0.55, IcmPos.sb: 0.45},
        stackBbPct: {
          StackBin.bb5: 0.35,
          StackBin.bb10: 0.40,
          StackBin.bb15: 0.25
        },
        triplePct: {
          StackTriple.sss: 0.10,
          StackTriple.sms: 0.20,
          StackTriple.mms: 0.25,
          StackTriple.mls: 0.20,
          StackTriple.lms: 0.15,
          StackTriple.lls: 0.10,
        },
      );
}

List<IcmSpot> generateIcmJamSpots({
  required int seed,
  required int count,
  required IcmMix mix,
}) {
  final rng = Random(seed);
  final handSet = <String>{}
    ..addAll(HandRangeLibrary.getGroup('broadways'))
    ..addAll(HandRangeLibrary.getGroup('pockets'))
    ..addAll(HandRangeLibrary.getGroup('suitedAx'))
    ..addAll(HandRangeLibrary.getGroup('suitedconnectors'));
  final hands = handSet.toList()..sort();
  final used = <String>{};
  final spots = <IcmSpot>[];
  var attempts = 0;
  final maxAttempts = count * 50;
  while (spots.length < count && attempts < maxAttempts) {
    attempts++;
    final hand = hands[rng.nextInt(hands.length)];
    final pos = _pickWeighted(rng, mix.posPct);
    final stack = _pickWeighted(rng, mix.stackBbPct);
    final triple = _pickWeighted(rng, mix.triplePct);
    final action = PfIcmAdapter.jamOrFold(hand, pos, stack, triple);
    final spot = IcmSpot(
      hand: hand,
      heroPos: pos,
      stacks: triple,
      stackBb: stack,
      action: action,
    );
    final key = spot.toString();
    if (used.add(key)) {
      spots.add(spot);
    }
  }
  if (spots.length < count) {
    for (final hand in hands) {
      for (final pos in IcmPos.values) {
        for (final stack in StackBin.values) {
          for (final triple in StackTriple.values) {
            final action = PfIcmAdapter.jamOrFold(hand, pos, stack, triple);
            final spot = IcmSpot(
              hand: hand,
              heroPos: pos,
              stacks: triple,
              stackBb: stack,
              action: action,
            );
            final key = spot.toString();
            if (used.add(key)) {
              spots.add(spot);
              if (spots.length >= count) return spots;
            }
          }
        }
      }
    }
  }
  return spots;
}

E _pickWeighted<E>(Random r, Map<E, double> pct) {
  final x = r.nextDouble();
  var cumulative = 0.0;
  for (final entry in pct.entries) {
    cumulative += entry.value;
    if (x < cumulative) return entry.key;
  }
  return pct.keys.last;
}

class PfIcmAdapter {
  static IcmAction jamOrFold(
    String hand,
    IcmPos heroPos,
    StackBin stackBb,
    StackTriple triple,
  ) {
    final base = kPushFoldThresholds[hand];
    if (base == null) return IcmAction.fold;
    final rp = _rpBy(heroPos, triple);
    final thr = base - rp;
    final bb = _bbValue(stackBb);
    return bb <= thr ? IcmAction.jam : IcmAction.fold;
  }

  static int _rpBy(IcmPos pos, StackTriple triple) {
    final tier = triple.name[0];
    int rp;
    switch (pos) {
      case IcmPos.btn:
        if (tier == 's') {
          rp = 6;
        } else if (tier == 'm') {
          rp = 3;
        } else {
          rp = 0;
        }
        break;
      case IcmPos.sb:
        if (tier == 's') {
          rp = 8;
        } else if (tier == 'm') {
          rp = 4;
        } else {
          rp = 1;
        }
        break;
    }
    if (rp < 0) return 0;
    if (rp > 20) return 20;
    return rp;
  }

  static int _bbValue(StackBin b) {
    switch (b) {
      case StackBin.bb5:
        return 5;
      case StackBin.bb10:
        return 10;
      case StackBin.bb15:
        return 15;
    }
  }
}
