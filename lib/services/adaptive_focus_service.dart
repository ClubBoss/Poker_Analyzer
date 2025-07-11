import 'package:flutter/foundation.dart';
import '../models/v2/hero_position.dart';
import 'saved_hand_manager_service.dart';
import '../helpers/poker_position_helper.dart';

class FocusStats {
  final HeroPosition position;
  final double accShort;
  final double accLong;
  final double evShort;
  final double evLong;
  final int shortHands;
  final int longHands;
  const FocusStats({
    required this.position,
    required this.accShort,
    required this.accLong,
    required this.evShort,
    required this.evLong,
    required this.shortHands,
    required this.longHands,
  });

  double get score {
    var s = (1 - accShort) + (evShort < 0 ? -evShort : 0);
    s += ((1 - accLong) + (evLong < 0 ? -evLong : 0)) * 0.5;
    return s;
  }
}

class AdaptiveFocusService extends ChangeNotifier {
  final SavedHandManagerService hands;
  FocusStats? _current;
  FocusStats? get current => _current;

  AdaptiveFocusService({required this.hands}) {
    _update();
    hands.addListener(_update);
  }

  void _update() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final all = <HeroPosition, List<_Entry>>{};
    for (final h in hands.hands) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp == null || gto == null) continue;
      final pos = parseHeroPosition(h.heroPosition);
      all.putIfAbsent(pos, () => []);
      all[pos]!.add(
        _Entry(
          correct: exp == gto,
          ev: h.heroEv,
          date: h.date,
        ),
      );
    }
    FocusStats? best;
    var bestScore = 0.0;
    for (final e in all.entries) {
      final short = e.value.where((v) => v.date.isAfter(cutoff)).toList();
      if (short.length < 5) continue;
      final longAcc = _accuracy(e.value);
      final shortAcc = _accuracy(short);
      final longEv = _evAvg(e.value);
      final shortEv = _evAvg(short);
      final stats = FocusStats(
        position: e.key,
        accShort: shortAcc,
        accLong: longAcc,
        evShort: shortEv,
        evLong: longEv,
        shortHands: short.length,
        longHands: e.value.length,
      );
      final s = stats.score;
      if (best == null || s > bestScore) {
        best = stats;
        bestScore = s;
      }
    }
    _current = best;
    notifyListeners();
  }

  double _accuracy(List<_Entry> list) {
    if (list.isEmpty) return 0;
    final correct = list.where((e) => e.correct).length;
    return correct / list.length;
  }

  double _evAvg(List<_Entry> list) {
    var sum = 0.0;
    var count = 0;
    for (final e in list) {
      if (e.ev != null) {
        sum += e.ev!;
        count += 1;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  @override
  void dispose() {
    hands.removeListener(_update);
    super.dispose();
  }
}

class _Entry {
  final bool correct;
  final double? ev;
  final DateTime date;
  _Entry({required this.correct, this.ev, required this.date});
}
