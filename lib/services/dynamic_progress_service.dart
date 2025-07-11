import 'package:flutter/foundation.dart';
import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';
import 'real_time_stack_range_service.dart';

class DynamicProgressData {
  final double accuracy;
  final double ev;
  final double icm;
  const DynamicProgressData({this.accuracy = 0, this.ev = 0, this.icm = 0});
}

class DynamicProgressService extends ChangeNotifier {
  final SavedHandManagerService hands;
  final RealTimeStackRangeService stack;
  DynamicProgressData _current = const DynamicProgressData();
  DynamicProgressData _delta = const DynamicProgressData();
  DynamicProgressData get current => _current;
  DynamicProgressData get delta => _delta;

  DynamicProgressService({required this.hands, required this.stack}) {
    _update();
    hands.addListener(_update);
    stack.addListener(_update);
  }

  void _update() {
    final target = stack.stack;
    final filtered = hands.hands.reversed.where((h) {
      final s = h.stackSizes[h.heroIndex] ?? 0;
      return (s - target).abs() <= 2;
    }).toList();
    final recent = filtered.take(20).toList();
    final prev = filtered.skip(20).take(20).toList();
    _current = _calc(recent);
    final p = _calc(prev);
    _delta = DynamicProgressData(
      accuracy: _current.accuracy - p.accuracy,
      ev: _current.ev - p.ev,
      icm: _current.icm - p.icm,
    );
    notifyListeners();
  }

  DynamicProgressData _calc(List<SavedHand> list) {
    if (list.isEmpty) return const DynamicProgressData();
    var handsCount = 0;
    var correct = 0;
    var ev = 0.0;
    var icm = 0.0;
    var evc = 0;
    for (final h in list) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null) {
        handsCount++;
        if (exp == gto) correct++;
      }
      final hev = h.heroEv;
      if (hev != null) {
        ev += hev;
        icm += h.heroIcmEv ?? 0;
        evc++;
      }
    }
    return DynamicProgressData(
      accuracy: handsCount > 0 ? correct / handsCount : 0,
      ev: evc > 0 ? ev / evc : 0,
      icm: evc > 0 ? icm / evc : 0,
    );
  }

  @override
  void dispose() {
    hands.removeListener(_update);
    stack.removeListener(_update);
    super.dispose();
  }
}
