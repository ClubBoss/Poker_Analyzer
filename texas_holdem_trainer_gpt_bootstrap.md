# Texas Hold'em Trainer — GPT Bootstrap

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
Full human-readable list, append-only mirror of curriculum_ids.dart.  
Append-only. If mismatch with code, code wins.

1. core_rules_and_setup
2. core_pot_odds_equity
3. core_starting_hands
4. core_flop_play
5. core_turn_river_play
6. core_blockers_combos
7. core_equity_realization
8. core_bet_sizing_fe
9. core_gto_vs_exploit
10. core_bankroll_management
11. core_mental_game
12. core_note_taking
13. cash_rake_and_stakes
14. cash_single_raised_pots
15. cash_threebet_pots
16. cash_multiway_pots
17. cash_blind_defense
18. cash_isolation_raises
19. cash_short_handed
20. cash_population_exploits
21. mtt_antes_phases
22. mtt_short_stack
23. mtt_mid_stack
24. mtt_deep_stack
25. mtt_icm_basics
26. mtt_bubble_and_FT
27. mtt_pko_strategy
28. mtt_satellite_strategy
29. hu_preflop_strategy
30. hu_postflop_play
31. hu_exploit_adv
32. spr_basics
33. live_tells_and_dynamics
34. online_tells_and_dynamics
35. hu_preflop
36. hu_postflop
37. hu_turn_play
38. core_board_textures            (S)
39. core_river_play               (S)
40. core_check_raise_systems      (S)
41. cash_blind_vs_blind           (S)
42. cash_fourbet_pots             (S)
43. hu_river_play                 (S)
44. spr_advanced                  (A)
45. cash_multiway_3bet_pots       (A)
46. cash_delayed_cbet_and_probe_systems (A)
47. cash_overbets_and_blocker_bets (A)
48. mtt_icm_endgame_advanced      (A)
49. mtt_final_table_playbooks     (A)
50. mtt_late_reg_strategy         (A)
51. exploit_advanced              (B)
52. hand_reading_and_range_construction (B)
53. live_etiquette_and_procedures (B)
54. online_table_selection_and_multitabling (B)
55. review_workflow_and_study_routines (B)
56. donk_bets_and_leads           (B)
57. cash_squeeze_strategy         (A)
58. icm_bubble_blind_vs_blind     (A)
59. live_full_ring_adjustments    (B)
60. online_fastfold_pool_dynamics (A)
61. cash_limp_pots_systems        (A)
62. mtt_pko_advanced_bounty_routing (A)
63. mtt_day2_bagging_and_reentry_ev (A)
64. database_leakfinder_playbook  (A)
65. solver_node_locking_basics    (A)
66. live_special_formats_straddle_bomb_ante (B)
67. online_economics_rakeback_promos (B)
68. hudless_strategy_and_note_coding (B)
69. hand_review_and_annotation_standards (B)

## Verification
- Run `dart test test/content_schema_test.dart` after every content PR.
- Run `dart format . && dart analyze` before commit.
- Roadmap consistency checked manually via diff with curriculum_ids.dart.
