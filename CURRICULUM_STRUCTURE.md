CURRICULUM_STRUCTURE.md
# Ultimate Curriculum v3.1 - Texas Hold'em Trainer

## Core (обязательный путь)
- core_rules_and_setup
- core_positions_and_initiative
- core_pot_odds_equity
- core_starting_hands
- core_flop_fundamentals
- core_turn_fundamentals
- core_river_fundamentals
- core_board_textures
- core_equity_realization
- core_bet_sizing_fe
- core_check_raise_systems
- core_gto_vs_exploit
- core_bankroll_management
- core_mental_game
- core_note_taking

---

## Cash (ветка после Core)
- cash_rake_and_stakes
- cash_single_raised_pots
- cash_threebet_pots
- cash_fourbet_pots
- cash_multiway_pots
- cash_multiway_3bet_pots
- cash_blind_defense
- cash_blind_vs_blind
- cash_isolation_raises
- cash_squeeze_strategy
- cash_short_handed
- cash_population_exploits
- cash_limp_pots_systems
- cash_delayed_cbet_and_probe_systems
- cash_overbets_and_blocker_bets

---

## MTT (ветка после Core)
- mtt_antes_phases
- mtt_short_stack
- mtt_mid_stack
- mtt_deep_stack
- mtt_icm_basics
- mtt_icm_endgame_advanced
- mtt_pko_strategy
- mtt_pko_advanced_bounty_routing
- mtt_satellite_strategy
- mtt_day2_bagging_and_reentry_ev
- mtt_final_table_playbooks
- mtt_late_reg_strategy
- icm_bubble_blind_vs_blind

---

## Heads-Up (HU, отдельная ветка)
- hu_preflop
- hu_postflop
- hu_turn_play
- hu_river_play
- hu_preflop_strategy
- hu_postflop_play
- hu_exploit_adv

---

## Math (отдельная ветка, постепенно углубляется)
- math_intro_basics
- math_pot_odds_equity
- math_combo_blockers
- math_ev_calculations
- math_icm_basics
- math_icm_advanced
- math_solver_basics
- solver_node_locking_basics

---

## Cross / Online dynamics
- online_tells_and_dynamics
- online_table_selection_and_multitabling
- online_fastfold_pool_dynamics
- online_economics_rakeback_promos
- hudless_strategy_and_note_coding
- exploit_advanced
- donk_bets_and_leads
- spr_basics
- spr_advanced
- hand_review_and_annotation_standards
- review_workflow_and_study_routines
- database_leakfinder_playbook

---

## Live overlay (append-only)
applies_to: [cash, mtt]  
default_mode: online  
mode: overlay  
prerequisites: [core_*]

order:
  - live_tells_and_dynamics
  - live_etiquette_and_procedures
  - live_full_ring_adjustments
  - live_special_formats_straddle_bomb_ante
  - live_table_selection_and_seat_change
  - live_chip_handling_and_bet_declares
  - live_speech_timing_basics
  - live_rake_structures_and_tips
  - live_floor_calls_and_dispute_resolution
  - live_session_log_and_review
  - live_security_and_game_integrity

runtime_flags:
  - has_straddle
  - bomb_ante
  - multi_limpers
  - announce_required
  - rake_type(time|drop)
  - avg_stack_bb
  - table_speed

live_validations:
  - string_bet
  - single_motion_raise_legal
  - bettor_shows_first
  - first_active_left_of_btn_shows

telemetry_dims:
  - track:<cash|mtt>
  - mode:<live|online>
