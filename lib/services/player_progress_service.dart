import 'package:flutter/foundation.dart';
import '../models/v2/hero_position.dart';
import 'saved_hand_manager_service.dart';

class PositionProgress {
  final int hands;
  final int correct;
  final double ev;
  final double icm;
  const PositionProgress(
      {this.hands = 0, this.correct = 0, this.ev = 0, this.icm = 0});
  double get accuracy => hands > 0 ? correct / hands : 0;
}

class PlayerProgressService extends ChangeNotifier {
  final SavedHandManagerService hands;
  Map<HeroPosition, PositionProgress> _progress = {};
  Map<HeroPosition, PositionProgress> get progress => _progress;
  PlayerProgressService({required this.hands}) {
    _update();
    hands.addListener(_update);
  }

  void _update() {
    final map = <HeroPosition, List<PositionProgress>>{};
    for (final h in hands.hands) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp == null || gto == null) continue;
      final pos = parseHeroPosition(h.heroPosition);
      final list = map.putIfAbsent(pos, () => []);
      final ev = h.heroEv ?? 0;
      final icm = h.heroIcmEv ?? 0;
      final correct = exp == gto ? 1 : 0;
      list.add(PositionProgress(hands: 1, correct: correct, ev: ev, icm: icm));
    }
    final result = <HeroPosition, PositionProgress>{};
    for (final e in map.entries) {
      final hands = e.value.length;
      final correct = e.value.fold(0, (p, v) => p + v.correct);
      final ev = e.value.fold(0.0, (p, v) => p + v.ev) / hands;
      final icm = e.value.fold(0.0, (p, v) => p + v.icm) / hands;
      result[e.key] =
          PositionProgress(hands: hands, correct: correct, ev: ev, icm: icm);
    }
    _progress = result;
    notifyListeners();
  }

  @override
  void dispose() {
    hands.removeListener(_update);
    super.dispose();
  }
}
