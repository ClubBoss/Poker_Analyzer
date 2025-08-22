import '../helpers/hand_utils.dart';
import '../models/mistake.dart';
import '../models/v2/hero_position.dart';
import 'pack_generator_service.dart';
import '../widgets/poker_table_view.dart' show PlayerAction;

class MistakeCategorizationEngine {
  MistakeCategorizationEngine();

  double computeHandStrength(String cards) {
    final code = handCode(cards);
    if (code == null) return 0;
    final idx = PackGeneratorService.handRanking.indexOf(code);
    if (idx < 0) return 0;
    return 1 - idx / (PackGeneratorService.handRanking.length - 1);
  }

  String categorize(Mistake mistake) {
    final exp = mistake.spot.evalResult?.expectedAction.toLowerCase();
    final pos = mistake.spot.hand.position;
    final a = mistake.action;
    final s = mistake.handStrength;
    String r = 'Unclassified';
    if (a == PlayerAction.fold && exp != 'fold') {
      r = s > 0.6 ? 'Overfold' : 'Too Passive';
    } else if (a == PlayerAction.call && exp == 'fold') {
      r = 'Overcall';
    } else if (a == PlayerAction.push && exp == 'call') {
      r = 'Wrong Push';
    } else if (a == PlayerAction.call && exp == 'push') {
      r = 'Wrong Call';
    } else if ((a == PlayerAction.check || a == PlayerAction.call) &&
        (exp == 'raise' || exp == 'bet' || exp == 'push')) {
      r = 'Missed Value';
    } else if ((a == PlayerAction.check || a == PlayerAction.fold) &&
        exp == 'call') {
      r = 'Too Passive';
    } else if ((a == PlayerAction.raise || a == PlayerAction.push) &&
        (exp == 'check' || exp == 'call' || exp == 'fold')) {
      if (exp == 'call' &&
          (pos == HeroPosition.utg || pos == HeroPosition.mp)) {
        r = 'Wrong Push';
      } else {
        r = 'Too Aggro';
      }
    }
    mistake.category = r;
    return r;
  }
}
