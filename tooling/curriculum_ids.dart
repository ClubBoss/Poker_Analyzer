// SSOT: append-only list of module IDs for Poker Analyzer curriculum.
// Order must match the roadmap docs. Indices are persistent.
// Do not rename/reorder existing entries.

const List<String> kCurriculumIds = [
  "core_rules_and_setup",
  "core_pot_odds_equity",
  "core_starting_hands",
  "core_flop_play",
  "core_turn_river_play",
  "core_blockers_combos",
  "core_equity_realization",
  "core_bet_sizing_fe",
  "core_gto_vs_exploit",
  "core_bankroll_management",
  "core_mental_game",
  "core_note_taking",
  "cash_rake_and_stakes",
  "cash_single_raised_pots",
  "cash_threebet_pots",
  "cash_multiway_pots",
  "cash_blind_defense",
  "cash_isolation_raises",
  "cash_short_handed",
  "cash_population_exploits",
  "mtt_antes_phases",
  "mtt_short_stack",
  "mtt_mid_stack",
  "mtt_deep_stack",
  "mtt_icm_basics",
  "mtt_bubble_and_FT",
  "mtt_pko_strategy",
  "mtt_satellite_strategy",
  "hu_preflop_strategy",
  "hu_postflop_play",
  "hu_exploit_adv",
  "spr_basics",
  "live_tells_and_dynamics",
  "online_tells_and_dynamics",
  "hu_preflop",
  "hu_postflop",
  "hu_turn_play",
  "hu_river_play",
  "core_positions_and_initiative",
  "core_board_textures",
  "core_river_play",
  "core_check_raise_systems",
  "cash_blind_vs_blind",
  "cash_fourbet_pots",
  "spr_advanced",
  "cash_multiway_3bet_pots",
  "cash_delayed_cbet_and_probe_systems",
  "cash_overbets_and_blocker_bets",
  "mtt_icm_endgame_advanced",
  "mtt_final_table_playbooks",
  "mtt_late_reg_strategy",
  "exploit_advanced",
  "hand_reading_and_range_construction",
  "live_etiquette_and_procedures",
  "online_table_selection_and_multitabling",
  "review_workflow_and_study_routines",
  "donk_bets_and_leads",
  "cash_squeeze_strategy",
  "icm_bubble_blind_vs_blind",
  "live_full_ring_adjustments",
  "online_fastfold_pool_dynamics",
  "cash_limp_pots_systems",
  "mtt_pko_advanced_bounty_routing",
  "mtt_day2_bagging_and_reentry_ev",
  "database_leakfinder_playbook",
  "solver_node_locking_basics",
  "live_special_formats_straddle_bomb_ante",
  "online_economics_rakeback_promos",
  "hudless_strategy_and_note_coding",
  "hand_review_and_annotation_standards",
];

// Back-compat alias for tests.
const List<String> kCurriculumModuleIds = kCurriculumIds;

/// Returns the first base module that is missing/misaligned vs [done].
/// If [done] is a strict prefix, returns the next item; if fully aligned, returns null.
String? firstMissing(List<String> done) {
  final base = kCurriculumModuleIds;
  final len = done.length < base.length ? done.length : base.length;
  for (var i = 0; i < len; i++) {
    if (done[i] != base[i]) return base[i];
  }
  if (done.length < base.length) return base[done.length];
  return null;
}
