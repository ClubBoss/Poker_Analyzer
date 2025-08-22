import '../models/spot_type.dart';
import '../models/v2/training_pack_spot.dart';

class TrainingSpotTypeClassifier {
  TrainingSpotTypeClassifier();

  SpotType classify(TrainingPackSpot spot) {
    final heroStack = spot.hand.stacks['${spot.hand.heroIndex}'] ?? 0.0;

    String heroAction = '';
    if (spot.correctAction != null && spot.correctAction!.isNotEmpty) {
      heroAction = spot.correctAction!.toLowerCase();
    } else if (spot.heroOptions.isNotEmpty) {
      heroAction = spot.heroOptions.first.toLowerCase();
    } else if (spot.evalResult?.expectedAction.isNotEmpty == true) {
      heroAction = spot.evalResult!.expectedAction.toLowerCase();
    } else {
      final acts = spot.hand.actions[0] ?? [];
      for (final a in acts) {
        if (a.playerIndex == spot.hand.heroIndex) {
          heroAction = a.action.toLowerCase();
          break;
        }
      }
    }

    final preflopActs = spot.hand.actions[0] ?? [];
    bool openBeforeHero = false;
    for (final a in preflopActs) {
      if (a.playerIndex == spot.hand.heroIndex) break;
      final act = a.action.toLowerCase();
      if (act == 'open' || act == 'raise' || act == 'bet' || act == 'push') {
        openBeforeHero = true;
      }
    }

    if (heroStack <= 15 && heroAction == 'push' && !openBeforeHero) {
      return SpotType.pushfold;
    }

    if (heroAction == 'push' && openBeforeHero) {
      return SpotType.isoPush;
    }

    if ((heroAction == '3bet' || heroAction == '3betpush') && heroStack > 20) {
      return SpotType.threeBet;
    }

    if (spot.hand.board.isNotEmpty) {
      return SpotType.postflopJam;
    }

    if (spot.hand.playerCount - 1 > 2) {
      return SpotType.multiway;
    }

    final tags = {for (final t in spot.tags) t.toLowerCase()};
    if (tags.contains('icm')) return SpotType.icm;

    return SpotType.unknown;
  }
}
