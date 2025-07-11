import 'package:flutter/foundation.dart';
import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';

class DynamicProgressEntry {
  final DateTime date;
  final double accuracy;
  final double ev;
  final double icm;
  const DynamicProgressEntry({
    required this.date,
    required this.accuracy,
    required this.ev,
    required this.icm,
  });
}

class DynamicProgressService extends ChangeNotifier {
  final SavedHandManagerService hands;
  List<DynamicProgressEntry> _history = const [];
  List<DynamicProgressEntry> get history => List.unmodifiable(_history);
  DynamicProgressEntry get latest =>
      _history.isNotEmpty ? _history.last : const DynamicProgressEntry(date: DateTime(0), accuracy: 0, ev: 0, icm: 0);
  DynamicProgressEntry? get previous =>
      _history.length >= 2 ? _history[_history.length - 2] : null;

  DynamicProgressService({required this.hands}) {
    _update();
    hands.addListener(_update);
  }

  void _update() {
    final map = <int, List<SavedHand>>{};
    for (final h in hands.hands) {
      final id = h.sessionId;
      if (id == 0) continue;
      map.putIfAbsent(id, () => []).add(h);
    }
    final entries = map.values.toList()
      ..sort((a, b) => a.first.date.compareTo(b.first.date));
    final hist = <DynamicProgressEntry>[];
    for (final list in entries) {
      int total = 0;
      int correct = 0;
      double ev = 0;
      int evCnt = 0;
      double icm = 0;
      for (final h in list) {
        final exp = h.expectedAction?.trim().toLowerCase();
        final gto = h.gtoAction?.trim().toLowerCase();
        if (exp != null && gto != null) {
          total++;
          if (exp == gto) correct++;
        }
        final hev = h.heroEv;
        if (hev != null) {
          ev += hev;
          evCnt++;
        }
        final hicm = h.heroIcmEv;
        if (hicm != null) icm += hicm;
      }
      if (total == 0) continue;
      final d = list.first.date;
      hist.add(DynamicProgressEntry(
        date: DateTime(d.year, d.month, d.day),
        accuracy: correct / total,
        ev: evCnt > 0 ? ev / evCnt : 0,
        icm: evCnt > 0 ? icm / evCnt : 0,
      ));
    }
    _history = hist;
    notifyListeners();
  }

  @override
  void dispose() {
    hands.removeListener(_update);
    super.dispose();
  }
}
