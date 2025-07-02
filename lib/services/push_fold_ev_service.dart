import 'pack_generator_service.dart';
import '../helpers/hand_utils.dart';
import '../models/action_entry.dart';
import '../models/v2/training_pack_spot.dart';

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
    final pot = (bbCount * anteBb) + 1.5 + anteBb;
    final bet = heroBbStack.toDouble();
    return eq * pot - (1 - eq) * bet;
  });
}

class PushFoldEvService {
  const PushFoldEvService();

  Future<void> evaluate(TrainingPackSpot spot) async {
    final hero = spot.hand.heroIndex;
    final hand = handCode(spot.hand.heroCards);
    final stack = spot.hand.stacks['$hero']?.round();
    if (hand == null || stack == null) return;
    final acts = spot.hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == hero && a.action == 'push') {
        a.ev = computePushEV(
          heroBbStack: stack,
          bbCount: spot.hand.playerCount - 1,
          heroHand: hand,
          anteBb: 0,
        );
        break;
      }
    }
  }
}
