/// Merges two tag mastery maps using weighted interpolation.
class MasterySyncService {
  /// Returns a new mastery map by blending [incoming] into [current].
  ///
  /// [incomingWeight] determines how much influence the incoming values have.
  /// Values are clamped to the `[0.0, 1.0]` range.
  Map<String, double> merge({
    required Map<String, double> current,
    required Map<String, double> incoming,
    double incomingWeight = 0.5,
  }) {
    final weight = incomingWeight.clamp(0.0, 1.0);
    final result = Map<String, double>.from(current);
    for (final entry in incoming.entries) {
      final tag = entry.key.trim().toLowerCase();
      if (tag.isEmpty) continue;
      final inc = entry.value;
      if (inc.isNaN || inc.isInfinite) continue;
      final old = result[tag] ?? 0.5;
      final blended = old * (1 - weight) + inc * weight;
      result[tag] = blended.clamp(0.0, 1.0);
    }
    return result;
  }
}
