const List<String> kCurriculumModuleIds = [
  'core_rules_and_setup',
  'core_pot_odds_equity',
  'core_starting_hands',
  'core_flop_play',
  'core_turn_river_play',
  'core_blockers_combos',
  'core_equity_realization',
  'core_bet_sizing_fe',
  'core_gto_vs_exploit',
  'core_bankroll_management',
  'core_mental_game',
  'core_note_taking',
  'cash_rake_and_stakes',
  'cash_single_raised_pots',
  'cash_threebet_pots',
  'cash_multiway_pots',
  'cash_blind_defense',
  'cash_isolation_raises',
  'cash_short_handed',
  'cash_population_exploits',
  'mtt_antes_phases',
  'mtt_short_stack',
  'mtt_mid_stack',
  'mtt_deep_stack',
  'mtt_icm_basics',
  'mtt_bubble_and_FT',
  'mtt_pko_strategy',
  'mtt_satellite_strategy',
  'hu_preflop_strategy',
  'hu_postflop_play',
  'hu_exploit_adv',
  'spr_basics',
  'live_tells_and_dynamics',
  'online_tells_and_dynamics',
  'hu_preflop',
  'hu_postflop',
  'hu_turn_play',
  'hu_river_play',
];

String? firstMissing(Iterable<String> done) {
  final doneSet = done.toSet();
  for (final id in kCurriculumModuleIds) {
    if (!doneSet.contains(id)) {
      return id;
    }
  }
  return null;
}

/// Human-readable titles for modules; keys must match kCurriculumModuleIds entries.
const Map<String, String> kModuleTitles = {
  'cash:l3:v1': 'Cash L3 • Jam vs Raise',
  'icm:l4:sb:v1': 'ICM L4 • SB Jam vs Fold',
  'icm:l4:bb:v1': 'ICM L4 • BB Jam vs Fold',
  'icm:l4:mix:v1': 'ICM L4 • Mixed Pack',
  'icm:l4:bubble:v1': 'ICM L4 • Bubble',
  'icm:l4:ladder:v1': 'ICM L4 • Ladder',
};
