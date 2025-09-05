// ASCII-only; pure Dart.

import 'package:poker_analyzer/infra/kpi_gate.dart';

/// Builds additive KPI-related fields for a session_end payload.
/// Pure helper; no side effects. Safe to import in pure-Dart tests.
Map<String, Object?> kpiFields({
  String? moduleId,
  int? total,
  int? correct,
  int? avgMs,
  bool enabled = false,
}) {
  final Map<String, Object?> out = {
    'session_module_id': moduleId,
    'session_total': total,
    'session_correct': correct,
    'session_avg_decision_ms': avgMs,
    'kpi_enabled': enabled,
  };
  final KPITarget target = kModuleKPI[moduleId ?? ''] ?? const KPITarget(80, 25000);
  out['kpi_target_accuracy'] = target.minAccuracyPct;
  out['kpi_target_time_ms'] = target.maxAvgMs;
  if (enabled && moduleId != null && total != null && correct != null && avgMs != null) {
    final int acc = total == 0 ? 0 : ((100 * correct) / total).round();
    out['kpi_met'] = acc >= target.minAccuracyPct && avgMs <= target.maxAvgMs;
  }
  return out;
}
