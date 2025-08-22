import '../models/training_track_summary.dart';

/// Updates tag mastery values based on a completed training track summary.
class TagMasteryUpdater {
  TagMasteryUpdater();

  /// Returns an updated copy of [current] with mastery adjusted using
  /// [summary]. The update moves mastery towards the observed accuracy
  /// by a fraction controlled by [learningRate].
  Map<String, double> updateMastery({
    required Map<String, double> current,
    required TrainingTrackSummary summary,
    double learningRate = 0.15,
  }) {
    final result = Map<String, double>.from(current);
    for (final entry in summary.tagBreakdown.entries) {
      final tag = entry.key.trim().toLowerCase();
      if (tag.isEmpty) continue;
      final old = result[tag] ?? 0.5;
      final acc = (entry.value.accuracy / 100).clamp(0.0, 1.0);
      final updated = (old + (acc - old) * learningRate).clamp(0.0, 1.0);
      result[tag] = updated;
    }
    return result;
  }
}
