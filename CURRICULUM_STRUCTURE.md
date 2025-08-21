# Curriculum Structure

## Overview
The Poker Analyzer curriculum is designed as a branching path:
- **Core** (mandatory fundamentals for all players).
- **Cash** (independent path for cash game development).
- **MTT** (independent path for tournaments).
- **Heads-Up (HU)** (independent branch unlocked after Core).
- **Specials / Meta** (optional advanced modules, unlocked after main branches).

This structure ensures smooth progression, minimal jargon, and step-by-step introduction of complexity.

---

## Branching Principles
- **Core** is required for everyone before branching.
- **Cash** and **MTT** are equal, parallel branches. Players may choose either path after Core.
- **HU** is independent: unlocked once the learner has completed Core and at least one pack of Cash or MTT.
- **Specials** are meta/advanced modules, optional but recommended for mastery.

---

## Style Principles
- **Audience**: user-friendly, amateur-friendly, mobile-first.
- **Clarity**: avoid unexplained jargon; every technical term must be defined the first time it appears.
- **Why & How**: each rule of thumb and common mistake must explain not only what, but also why it matters.
- **Gradual buildup**: start from basics, add complexity progressively. Don’t overload with math or solver jargon too early.
- **Contextual notes**: clarify when advice applies differently for live vs online.

---

## Batch Assignments

### Core (fundamentals for everyone)
- **Batch 1**: core_rules_and_setup, core_pot_odds_equity, core_starting_hands, core_flop_play  
- **Batch 2**: core_turn_river_play, core_blockers_combos, core_equity_realization, core_bet_sizing_fe  
- **Batch 3**: core_gto_vs_exploit, core_bankroll_management, core_mental_game, core_note_taking  
- **Batch 10**: hu_river_play, core_positions_and_initiative, core_board_textures, core_river_play  

### Cash Path
- **Batch 4**: cash_rake_and_stakes, cash_single_raised_pots, cash_threebet_pots, cash_multiway_pots  
- **Batch 5**: cash_blind_defense, cash_isolation_raises, cash_short_handed, cash_population_exploits  
- **Batch 11**: core_check_raise_systems, cash_blind_vs_blind, cash_fourbet_pots, spr_advanced  
- **Batch 12**: cash_multiway_3bet_pots, cash_delayed_cbet_and_probe_systems, cash_overbets_and_blocker_bets, mtt_icm_endgame_advanced (*hybrid, see MTT*)  
- **Batch 15**: cash_squeeze_strategy, icm_bubble_blind_vs_blind, live_full_ring_adjustments, online_fastfold_pool_dynamics (*hybrid*)  
- **Batch 16**: cash_limp_pots_systems, mtt_pko_advanced_bounty_routing, mtt_day2_bagging_and_reentry_ev, database_leakfinder_playbook (*hybrid*)  

### MTT Path
- **Batch 6**: mtt_antes_phases, mtt_short_stack, mtt_mid_stack, mtt_deep_stack  
- **Batch 7**: mtt_icm_basics, mtt_pko_strategy, mtt_satellite_strategy, hu_preflop_strategy (*HU crossover*)  
- **Batch 12**: includes mtt_icm_endgame_advanced (shared with Cash batch)  
- **Batch 13**: mtt_final_table_playbooks, mtt_late_reg_strategy, exploit_advanced, hand_reading_and_range_construction  
- **Batch 15**: includes icm_bubble_blind_vs_blind (shared with Cash batch)  
- **Batch 16**: includes mtt_pko_advanced_bounty_routing, mtt_day2_bagging_and_reentry_ev (shared with Cash batch)  

### Heads-Up (HU)
- **Batch 7**: hu_preflop_strategy (appears alongside MTT ICM basics)  
- **Batch 8**: hu_postflop_play, hu_exploit_adv, spr_basics, live_tells_and_dynamics (*HU + Specials*)  
- **Batch 9**: online_tells_and_dynamics, hu_preflop, hu_postflop, hu_turn_play  
- **Batch 10**: hu_river_play (appears with Core river content)  

### Specials / Meta
- **Batch 8**: includes live_tells_and_dynamics, spr_basics (mixed with HU)  
- **Batch 14**: live_etiquette_and_procedures, online_table_selection_and_multitabling, review_workflow_and_study_routines, donk_bets_and_leads  
- **Batch 15**: live_full_ring_adjustments, online_fastfold_pool_dynamics (mixed with Cash/MTT)  
- **Batch 16**: database_leakfinder_playbook (mixed with Cash/MTT)  
- **Batch 17**: solver_node_locking_basics, live_special_formats_straddle_bomb_ante, online_economics_rakeback_promos, hudless_strategy_and_note_coding, hand_review_and_annotation_standards  

---

## Notes on Hybrids
Some batches mix modules from different paths (e.g. Batch 12: Cash + MTT). This is intentional for content density and thematic grouping, but **learner progression should branch correctly in-app**.  

---

## Usage
- **Research chat** uses this file to generate correct content batches.  
- **Zip chat** packages and validates content, ensuring alignment with this structure.  
- **App logic** enforces progression rules based on branch unlocks.  

