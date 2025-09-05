// ASCII-only; pure Dart.

/// Feature flag for Rehab Hint (prod default: disabled).
const bool kEnableRehabHint = false;

/// Returns a list of suggested rehab modules based on KPI outcome
/// and the top weakness family observed during the session.
/// When the feature is disabled, returns an empty list.
List<String> rehabHint({required bool kpiMet, String? weaknessTop}) {
  if (!kEnableRehabHint) return const [];

  if (!kpiMet && weaknessTop == 'jam_vs_') {
    return const ['cash_threebet_pots'];
  }
  if (!kpiMet && weaknessTop == 'betting') {
    return const ['core_flop_fundamentals', 'cash_single_raised_pots'];
  }
  if (!kpiMet && weaknessTop == 'turn_control') {
    return const [
      'core_turn_fundamentals',
      'cash_delayed_cbet_and_probe_systems',
    ];
  }
  if (!kpiMet && weaknessTop == 'river') {
    return const ['core_river_fundamentals', 'cash_overbets_and_blocker_bets'];
  }
  return const [];
}
