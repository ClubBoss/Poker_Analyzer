import 'package:flutter/foundation.dart';
import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';

enum PlayerStyle { aggressive, passive, neutral }

class PlayerStyleService extends ChangeNotifier {
  final SavedHandManagerService hands;
  PlayerStyleService({required this.hands}) {
    _update();
    hands.addListener(_update);
  }

  PlayerStyle _style = PlayerStyle.neutral;
  PlayerStyle get style => _style;

  void _update() {
    int aggr = 0;
    int pass = 0;
    for (final SavedHand h in hands.hands.take(50)) {
      for (final a in h.actions) {
        if (a.playerIndex != h.heroIndex) continue;
        final act = a.action.toLowerCase();
        if (act == 'bet' ||
            act == 'raise' ||
            act == 'push' ||
            act == 'allin' ||
            act == 'all-in') {
          aggr++;
        } else if (act == 'call' || act == 'check' || act == 'fold') {
          pass++;
        }
      }
    }
    final total = aggr + pass;
    PlayerStyle newStyle = PlayerStyle.neutral;
    if (total >= 10) {
      final pct = aggr / total;
      if (pct > 0.6) {
        newStyle = PlayerStyle.aggressive;
      } else if (pct < 0.4)
        newStyle = PlayerStyle.passive;
    }
    if (newStyle != _style) {
      _style = newStyle;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    hands.removeListener(_update);
    super.dispose();
  }
}
