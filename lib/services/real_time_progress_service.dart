import 'package:flutter/foundation.dart';
import '../helpers/hand_utils.dart';
import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';
import 'real_time_stack_range_service.dart';

class RealTimeProgress {
  final double accuracy;
  final double ev;
  final double icm;
  const RealTimeProgress({
    required this.accuracy,
    required this.ev,
    required this.icm,
  });
}

class RealTimeProgressService extends ChangeNotifier {
  final SavedHandManagerService hands;
  final RealTimeStackRangeService stackRange;

  RealTimeProgress _progress = const RealTimeProgress(accuracy: 0, ev: 0, icm: 0);
  RealTimeProgress get progress => _progress;

  RealTimeProgressService({required this.hands, required this.stackRange}) {
    _update();
    hands.addListener(_update);
    stackRange.addListener(_update);
  }

  void _update() {
    final target = stackRange.stack;
    final codes = stackRange.range.toSet();
    var correct = 0;
    var total = 0;
    var evSum = 0.0;
    var icmSum = 0.0;
    var evCount = 0;
    for (final SavedHand h in hands.hands.reversed) {
      if (total >= 100) break;
      final heroStack = h.stackSizes[h.heroIndex];
      if (heroStack == null || (heroStack - target).abs() > 2) continue;
      if (h.playerCards.length <= h.heroIndex ||
          h.playerCards[h.heroIndex].length < 2) continue;
      final c1 = h.playerCards[h.heroIndex][0];
      final c2 = h.playerCards[h.heroIndex][1];
      final code = handCode('${c1.rank}${c1.suit} ${c2.rank}${c2.suit}');
      if (code != null && codes.isNotEmpty && !codes.contains(code)) continue;
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null) {
        total += 1;
        if (exp == gto) correct += 1;
      }
      final ev = h.heroEv;
      if (ev != null) {
        evSum += ev;
        evCount += 1;
      }
      final icm = h.heroIcmEv;
      if (icm != null) icmSum += icm;
    }
    final acc = total > 0 ? correct / total : 0.0;
    final avgEv = evCount > 0 ? evSum / evCount : 0.0;
    final avgIcm = evCount > 0 ? icmSum / evCount : 0.0;
    _progress =
        RealTimeProgress(accuracy: acc, ev: avgEv, icm: avgIcm);
    notifyListeners();
  }

  @override
  void dispose() {
    hands.removeListener(_update);
    stackRange.removeListener(_update);
    super.dispose();
  }
}
