/// Utility helpers for evaluating stack-related constraints.
class StackUtils {
  StackUtils._();

  /// Returns true if [stack] falls within the provided [min] and [max]
  /// thresholds. Null bounds are treated as unbounded in that direction.
  static bool inRange(double stack, {double? min, double? max}) {
    if (min != null && stack < min) return false;
    if (max != null && stack > max) return false;
    return true;
  }
}
