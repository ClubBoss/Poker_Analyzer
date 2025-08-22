import '../models/saved_hand.dart';
import '../models/mistake.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/evaluation_result.dart';
import '../widgets/poker_table_view.dart' show PlayerAction;
import '../helpers/hand_utils.dart';
import 'mistake_categorization_engine.dart';

class MistakeCategorizer {
  MistakeCategorizer();

  String classify(SavedHand hand) {
    final act = heroAction(hand)?.action;
    final gto = hand.gtoAction;
    if (act == null || gto == null) return 'Unclassified';
    final cards = hand.playerCards[hand.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final spot = TrainingPackSpot(
      id: hand.spotId ?? '',
      hand: HandData(
        heroCards: cards,
        position: parseHeroPosition(hand.heroPosition),
        heroIndex: hand.heroIndex,
        playerCount: hand.numberOfPlayers,
        anteBb: hand.anteBb,
      ),
      evalResult: EvaluationResult(
        correct: act.trim().toLowerCase() == gto.trim().toLowerCase(),
        expectedAction: gto,
        userEquity: 0,
        expectedEquity: 0,
      ),
    );
    final strength = const MistakeCategorizationEngine().computeHandStrength(
      cards,
    );
    final m = Mistake(
      spot: spot,
      action: _parseAction(act),
      handStrength: strength,
    );
    return const MistakeCategorizationEngine().categorize(m);
  }

  PlayerAction _parseAction(String a) {
    switch (a.toLowerCase()) {
      case 'fold':
        return PlayerAction.fold;
      case 'call':
        return PlayerAction.call;
      case 'push':
        return PlayerAction.push;
      case 'raise':
      case 'bet':
        return PlayerAction.raise;
      case 'post':
        return PlayerAction.post;
    }
    return PlayerAction.none;
  }
}
