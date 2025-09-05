// ASCII-only; pure Dart.

/// Feature flag for KPI gating (prod default: disabled).
const bool kEnableKPI = false;

/// Internal override to enable gating in tests.
/// Tests may set this to true; in prod it defaults to [kEnableKPI].
bool kEnableKPIOverride = kEnableKPI;

class KPITarget {
  final int minAccuracyPct;
  final int maxAvgMs;
  const KPITarget(this.minAccuracyPct, this.maxAvgMs);
}

/// Module-specific KPI targets. Append-only in future changes.
final Map<String, KPITarget> kModuleKPI = {
  // e.g. 'cash_threebet_pots': KPITarget(85, 20000),
};

bool meetsKPI({
  required String moduleId,
  required int correct,
  required int total,
  required int avgDecisionMs,
}) {
  if (!kEnableKPIOverride) return true;
  final KPITarget t = kModuleKPI[moduleId] ?? const KPITarget(80, 25000);
  final int acc = total == 0 ? 0 : ((100 * correct) / total).round();
  return acc >= t.minAccuracyPct && avgDecisionMs <= t.maxAvgMs;
}
