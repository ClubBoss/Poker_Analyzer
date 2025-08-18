import 'dart:math' as math;
import 'package:flutter/material.dart';

class SkillLoss {
  final String tag;
  final double drop;
  final String trend;

  SkillLoss({required this.tag, required this.drop, required this.trend});
}

class SkillLossDetector {
  const SkillLossDetector();

  List<SkillLoss> detect(
    Map<String, List<double>> tagHistory, {
    DateTimeRange? range,
  }) {
    final results = <SkillLoss>[];
    tagHistory.forEach((tag, history) {
      final data = history.where((e) => e.isFinite).toList();
      if (data.length < 3) return;
      final slope = _calcSlope(data);
      final sharpDrop = _hasSharpDrop(data);
      if (slope < 0 || sharpDrop) {
        final maxVal = data.reduce(math.max);
        final drop = (maxVal - data.last).clamp(0.0, double.infinity);
        final trend = sharpDrop ? 'Recent collapse' : 'Steady decline';
        if (drop > 0) {
          results.add(SkillLoss(tag: tag, drop: drop, trend: trend));
        }
      }
    });
    results.sort((a, b) => b.drop.compareTo(a.drop));
    return results;
  }

  double _calcSlope(List<double> list) {
    final n = list.length;
    final xs = [for (var i = 0; i < n; i++) (i + 1).toDouble()];
    final sumX = xs.reduce((a, b) => a + b);
    final sumX2 = xs.map((e) => e * e).reduce((a, b) => a + b);
    final sumY = list.reduce((a, b) => a + b);
    final sumXY = [
      for (var i = 0; i < n; i++) xs[i] * list[i],
    ].reduce((a, b) => a + b);
    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) return 0;
    return (n * sumXY - sumX * sumY) / denom;
  }

  bool _hasSharpDrop(List<double> list) {
    if (list.length < 3) return false;
    final last3 = list.sublist(list.length - 3);
    if (!(last3[0] > last3[1] && last3[1] > last3[2])) return false;
    final decline = last3.first - last3.last;
    if (decline <= 0) return false;
    final pct = decline / last3.first;
    return pct >= 0.1;
  }
}
