import 'package:flutter/foundation.dart';
import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';

class ProgressEntry {
  final DateTime date;
  final double accuracy;
  final double ev;
  final double icm;
  const ProgressEntry({
    required this.date,
    required this.accuracy,
    required this.ev,
    required this.icm,
  });
}

class ProgressForecast {
  final double accuracy;
  final double ev;
  final double icm;
  const ProgressForecast({
    required this.accuracy,
    required this.ev,
    required this.icm,
  });
}

class ProgressForecastService extends ChangeNotifier {
  final SavedHandManagerService hands;
  List<ProgressEntry> _history = const [];
  ProgressForecast _forecast = const ProgressForecast(accuracy: 0, ev: 0, icm: 0);

  List<ProgressEntry> get history => List.unmodifiable(_history);
  ProgressForecast get forecast => _forecast;

  ProgressForecastService({required this.hands}) {
    _update();
    hands.addListener(_update);
  }

  void _update() {
    final map = <DateTime, List<SavedHand>>{};
    for (final h in hands.hands) {
      final day = DateTime(h.date.year, h.date.month, h.date.day);
      map.putIfAbsent(day, () => []).add(h);
    }
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final hist = <ProgressEntry>[];
    for (final e in entries) {
      int correct = 0;
      int total = 0;
      double ev = 0;
      double icm = 0;
      int evCount = 0;
      for (final h in e.value) {
        final exp = h.expectedAction?.trim().toLowerCase();
        final gto = h.gtoAction?.trim().toLowerCase();
        if (exp != null && gto != null) {
          total++;
          if (exp == gto) correct++;
        }
        final hev = h.heroEv;
        if (hev != null) {
          ev += hev;
          evCount++;
        }
        final hicm = h.heroIcmEv;
        if (hicm != null) icm += hicm;
      }
      final acc = total > 0 ? correct / total : 0;
      final avgEv = evCount > 0 ? ev / evCount : 0;
      final avgIcm = evCount > 0 ? icm / evCount : 0;
      hist.add(ProgressEntry(date: e.key, accuracy: acc, ev: avgEv, icm: avgIcm));
    }
    _history = hist;
    _forecast = _calcForecast(hist);
    notifyListeners();
  }

  ProgressForecast _calcForecast(List<ProgressEntry> data) {
    if (data.isEmpty) return const ProgressForecast(accuracy: 0, ev: 0, icm: 0);
    if (data.length == 1) return ProgressForecast(
        accuracy: data.last.accuracy,
        ev: data.last.ev,
        icm: data.last.icm);
    final n = data.length;
    final xs = [for (var i = 0; i < n; i++) i + 1];
    final sumX = xs.reduce((a, b) => a + b);
    final sumX2 = xs.map((e) => e * e).reduce((a, b) => a + b);
    double sumAcc = 0, sumEv = 0, sumIcm = 0;
    double sumXAcc = 0, sumXEv = 0, sumXIcm = 0;
    for (var i = 0; i < n; i++) {
      final x = xs[i].toDouble();
      final d = data[i];
      sumAcc += d.accuracy;
      sumEv += d.ev;
      sumIcm += d.icm;
      sumXAcc += x * d.accuracy;
      sumXEv += x * d.ev;
      sumXIcm += x * d.icm;
    }
    final denom = n * sumX2 - sumX * sumX;
    double slopeAcc = 0, slopeEv = 0, slopeIcm = 0;
    if (denom != 0) {
      slopeAcc = (n * sumXAcc - sumX * sumAcc) / denom;
      slopeEv = (n * sumXEv - sumX * sumEv) / denom;
      slopeIcm = (n * sumXIcm - sumX * sumIcm) / denom;
    }
    return ProgressForecast(
      accuracy: (data.last.accuracy + slopeAcc).clamp(0.0, 1.0),
      ev: data.last.ev + slopeEv,
      icm: data.last.icm + slopeIcm,
    );
  }

  @override
  void dispose() {
    hands.removeListener(_update);
    super.dispose();
  }
}
