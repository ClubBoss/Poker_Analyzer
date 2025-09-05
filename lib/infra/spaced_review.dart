// ASCII-only; pure Dart.

/// Feature flag for spaced review timestamp (prod default: disabled).
const bool kEnableSpaced = false;

/// Computes next review timestamp based on KPI result and accuracy.
/// - If KPI not met: 1 day
/// - Else if accuracy < 85%: 3 days
/// - Else: 7 days
DateTime nextReviewTs({
  required bool kpiMet,
  required int correct,
  required int total,
}) {
  final int acc = total == 0 ? 0 : ((100 * correct) / total).round();
  final int days = !kpiMet ? 1 : (acc < 85 ? 3 : 7);
  return DateTime.now().add(Duration(days: days));
}
