# Experiment Flags

ASCII-only. Short notes for internal experiments.

## KPI Gate

- Flag: `kEnableKPI` (default: `false`)
- File: `lib/infra/kpi_gate.dart`
- Purpose: Gate module sessions behind simple targets
  - Target per module: `kModuleKPI[moduleId] = KPITarget(minAccuracyPct, maxAvgMs)`
  - Default target when none specified: 80% accuracy, 25,000 ms average decision time
- Telemetry (session_end) adds the following keys (additive only):
  - `session_module_id` (String | null)
  - `session_total` (int | null)
  - `session_correct` (int | null)
  - `session_avg_decision_ms` (int | null)
  - `kpi_enabled` (bool)
  - `kpi_target_accuracy` (int)
  - `kpi_target_time_ms` (int)
  - `kpi_met` (bool, present only when the flag is enabled and all session_* fields are available)

Note: The helper `kpiFields(...)` in `lib/infra/kpi_fields_pure.dart` builds these fields.

## Weakness Log

- Flag: `kEnableWeaknessLog` (default: `false`)
- File: `lib/infra/weakness_log.dart`
- Purpose: Lightweight per-family counters for mistakes
  - Call `weaknessLog.record(familyFor(spot.kind))` on wrong answers when `autoWhy` is enabled
  - Families: `jam_vs_`, `betting`, `turn_control`, `river`, `misc`

Both flags are disabled by default; flipping them should not impact production behavior until explicitly enabled.

When `kEnableWeaknessLog` is true, `session_end` telemetry may also include:
- `weakness_top_family` and `weakness_top_count` (if any data recorded)
