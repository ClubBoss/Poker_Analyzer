import '../models/unlock_condition.dart';

/// Evaluates [UnlockCondition]s based on provided progress and accuracy data.
class UnlockConditionEvaluator {
  UnlockConditionEvaluator();

  /// Returns `true` if [condition] is satisfied given [progress] and [accuracy].
  bool isUnlocked(
    UnlockCondition? condition,
    Map<String, double> progress,
    Map<String, double> accuracy,
  ) {
    if (condition == null) return true;
    final dep = condition.dependsOn;
    if (dep == null) return true;
    final prog = progress[dep] ?? 0.0;
    if (prog < 1.0) return false;
    final reqAcc = condition.minAccuracy?.toDouble() ?? 0.0;
    final acc = accuracy[dep] ?? 0.0;
    return acc >= reqAcc;
  }
}
