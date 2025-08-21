# Texas Hold'em Trainer — GPT Bootstrap (v3.1 aligned)

## Purpose
Bootstrap document to align Codex + Research + UX streams.  
SSOT for scope, cadence, and roadmap.

## Scope
- Skeleton → Content → UX polish
- Cash first, then MTT, then specializations
- Research batches drive content
- Codex drives loaders/status/tests

## Cadence
Loop = Prompt → Codex → PR → merge → Research content batch → PR → merge.  
One-at-a-time for Codex; batched for Research.

## Learning roadmap
Full human-readable list, append-only mirror of curriculum_ids.dart (v3.1).  
If mismatch with code, code wins.

### Core
core_rules_and_setup  
core_positions_and_initiative  
core_pot_odds_equity  
core_starting_hands  
core_flop_fundamentals  
core_turn_fundamentals  
core_river_fundamentals  
core_board_textures  
core_equity_realization  
core_bet_sizing_fe  
core_check_raise_systems  
core_gto_vs_exploit  
core_bankroll_management  
core_mental_game  
core_note_taking  

### Cash
cash_rake_and_stakes  
cash_single_raised_pots  
cash_threebet_pots  
cash_fourbet_pots  
cash_multiway_pots  
cash_multiway_3bet_pots  
cash_blind_defense  
cash_blind_vs_blind  
cash_isolation_raises  
cash_squeeze_strategy  
cash_short_handed  
cash_population_exploits  
cash_limp_pots_systems  
cash_delayed_cbet_and_probe_systems  
cash_overbets_and_blocker_bets  

### MTT
mtt_antes_phases  
mtt_short_stack  
mtt_mid_stack  
mtt_deep_stack  
mtt_icm_basics  
mtt_icm_endgame_advanced  
mtt_pko_strategy  
mtt_pko_advanced_bounty_routing  
mtt_satellite_strategy  
mtt_day2_bagging_and_reentry_ev  
mtt_final_table_playbooks  
mtt_late_reg_strategy  
icm_bubble_blind_vs_blind  

### Heads-Up (HU)
hu_preflop  
hu_postflop  
hu_turn_play  
hu_river_play  
hu_preflop_strategy  
hu_postflop_play  
hu_exploit_adv  

### Math
math_intro_basics  
math_pot_odds_equity  
math_combo_blockers  
math_ev_calculations  
math_icm_basics  
math_icm_advanced  
math_solver_basics  
solver_node_locking_basics  

### Cross / Live & Online dynamics
live_tells_and_dynamics  
live_etiquette_and_procedures  
live_full_ring_adjustments  
live_special_formats_straddle_bomb_ante  
online_tells_and_dynamics  
online_table_selection_and_multitabling  
online_fastfold_pool_dynamics  
online_economics_rakeback_promos  
hudless_strategy_and_note_coding  
exploit_advanced  
donk_bets_and_leads  
spr_basics  
spr_advanced  
hand_review_and_annotation_standards  
review_workflow_and_study_routines  
database_leakfinder_playbook  

## Verification
- Run `dart test test/content_schema_test.dart` after every content PR.
- Run `dart format . && dart analyze` before commit.
- Roadmap consistency checked manually via diff with curriculum_ids.dart.
