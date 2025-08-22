import '../core/training/engine/training_type_engine.dart';

class WeakTrainingTypeDetector {
  WeakTrainingTypeDetector();

  TrainingType? findWeakestType(Map<TrainingType, double> stats) {
    final filtered = <TrainingType, double>{};
    for (final entry in stats.entries) {
      if (entry.value < 100) filtered[entry.key] = entry.value;
    }
    if (filtered.isEmpty) return null;
    TrainingType weakest = filtered.keys.first;
    double minVal = filtered[weakest]!;
    for (final entry in filtered.entries) {
      if (entry.value < minVal) {
        minVal = entry.value;
        weakest = entry.key;
      }
    }
    return weakest;
  }
}
