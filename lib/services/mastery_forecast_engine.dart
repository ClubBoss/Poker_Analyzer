import 'dart:math';

/// Estimates potential EV gain from improving tag mastery.
class MasteryForecastEngine {
  MasteryForecastEngine();

  static const double _targetMastery = 0.9;
  static const double _targetEv = 0.95;

  /// Returns expected EV gain as a fraction (0.05 = 5% EV gain).
  double estimateEvGain({
    required String tag,
    required Map<String, double> tagMastery,
    double baselineEv = 0.75,
  }) {
    final mastery = tagMastery[tag.trim().toLowerCase()] ?? 0.0;
    if (mastery >= _targetMastery) return 0.0;
    final gainMastery = (_targetMastery - mastery).clamp(0.0, 1.0);
    final weight = max(0, _targetEv - baselineEv) / _targetMastery;
    return gainMastery * weight;
  }
}
