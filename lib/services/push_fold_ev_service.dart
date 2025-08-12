import 'pack_generator_service.dart';
import '../helpers/hand_utils.dart';
import '../models/v2/training_pack_spot.dart';
import 'icm_push_ev_service.dart';

final Map<String, double> _equity = {
  for (int i = 0; i < PackGeneratorService.handRanking.length; i++)
    PackGeneratorService.handRanking[i]:
        0.85 - i * (0.55 / (PackGeneratorService.handRanking.length - 1))
};

final Map<String, double> _evCache = {};

double computePushEV({
  required int heroBbStack,
  required int bbCount,
  required String heroHand,
  required int anteBb,
}) {
  final key = '$heroBbStack|$bbCount|$heroHand|$anteBb';
  return _evCache.putIfAbsent(key, () {
    final eq = _equity[heroHand] ?? 0.5;
    final pot = (bbCount + 1) * anteBb + 1.5;
    final bet = heroBbStack.toDouble();
    return eq * (pot + bet) - (1 - eq) * bet;
  });
}

double computeCallEV({
  required int heroBbStack,
  required int villainBbStack,
  required String heroHand,
  required int anteBb,
}) {
  final key = 'c|$heroBbStack|$villainBbStack|$heroHand|$anteBb';
  return _evCache.putIfAbsent(key, () {
    final eq = _equity[heroHand] ?? 0.5;
    final pot = 2 * anteBb + 1.5;
    final call = villainBbStack.toDouble();
    return eq * (pot + call) - (1 - eq) * call;
  });
}

class PushFoldEvService {
  const PushFoldEvService();

  Future<void> evaluate(TrainingPackSpot spot, {int anteBb = 0}) async {
    final hero = spot.hand.heroIndex;
    final hand = handCode(spot.hand.heroCards);
    final stack = spot.hand.stacks['$hero']?.round();
    if (hand == null || stack == null) return;
    final acts = spot.hand.actions[0] ?? [];
    for (var i = 0; i < acts.length; i++) {
      final a = acts[i];
      if (a.playerIndex == hero && a.action == 'push') {
        acts[i] = a.copyWith(
          ev: computePushEV(
            heroBbStack: stack,
            bbCount: spot.hand.playerCount - 1,
            heroHand: hand,
            anteBb: anteBb,
          ),
        );
        break;
      }
    }
  }

  Future<void> evaluateIcm(TrainingPackSpot spot,
      {int anteBb = 0, List<double> payouts = const [0.5, 0.3, 0.2]}) async {
    final hero = spot.hand.heroIndex;
    final hand = handCode(spot.hand.heroCards);
    final stack = spot.hand.stacks['$hero']?.round();
    if (hand == null || stack == null) return;
    final acts = spot.hand.actions[0] ?? [];
    final stacks = [
      for (var i = 0; i < spot.hand.playerCount; i++)
        spot.hand.stacks['$i']?.round() ?? 0
    ];
    for (var i = 0; i < acts.length; i++) {
      final a = acts[i];
      if (a.playerIndex == hero && a.action == 'push') {
        final chipEv = a.ev ?? computePushEV(
          heroBbStack: stack,
          bbCount: spot.hand.playerCount - 1,
          heroHand: hand,
          anteBb: anteBb,
        );
        acts[i] = a.copyWith(
          ev: a.ev ?? chipEv,
          icmEv: computeIcmPushEV(
            chipStacksBb: stacks,
            heroIndex: hero,
            heroHand: hand,
            chipPushEv: chipEv,
            payouts: payouts,
          ),
        );
        break;
      }
    }
  }
}
