import 'package:flutter/foundation.dart';
import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';
import 'player_style_service.dart';

class PlayerStyleForecastService extends ChangeNotifier {
  final SavedHandManagerService hands;
  PlayerStyleForecastService({required this.hands}) {
    _update();
    hands.addListener(_update);
  }

  PlayerStyle _forecast = PlayerStyle.neutral;
  PlayerStyle get forecast => _forecast;

  void _update() {
    final map = <DateTime, List<SavedHand>>{};
    for (final h in hands.hands) {
      final day = DateTime(h.date.year, h.date.month, h.date.day);
      map.putIfAbsent(day, () => []).add(h);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final ratios = <double>[];
    for (final e in entries) {
      var aggr = 0;
      var pass = 0;
      for (final h in e.value) {
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
      ratios.add(total > 0 ? aggr / total : 0.5);
    }
    final newForecast = _calcForecast(ratios);
    if (newForecast != _forecast) {
      _forecast = newForecast;
      notifyListeners();
    }
  }

  PlayerStyle _calcForecast(List<double> data) {
    if (data.isEmpty) return PlayerStyle.neutral;
    if (data.length == 1) return _ratioToStyle(data.last);
    final n = data.length;
    final xs = [for (var i = 0; i < n; i++) i + 1];
    final sumX = xs.reduce((a, b) => a + b);
    final sumX2 = xs.map((e) => e * e).reduce((a, b) => a + b);
    var sumY = 0.0;
    var sumXY = 0.0;
    for (var i = 0; i < n; i++) {
      final x = xs[i].toDouble();
      final y = data[i];
      sumY += y;
      sumXY += x * y;
    }
    final denom = n * sumX2 - sumX * sumX;
    var ratio = data.last;
    if (denom != 0) {
      final slope = (n * sumXY - sumX * sumY) / denom;
      ratio += slope;
    }
    ratio = ratio.clamp(0.0, 1.0);
    return _ratioToStyle(ratio);
  }

  PlayerStyle _ratioToStyle(double r) {
    if (r > 0.6) return PlayerStyle.aggressive;
    if (r < 0.4) return PlayerStyle.passive;
    return PlayerStyle.neutral;
  }

  @override
  void dispose() {
    hands.removeListener(_update);
    super.dispose();
  }
}
