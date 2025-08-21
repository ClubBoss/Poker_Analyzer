
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

1. intro_getting_started
2. core_rules_and_setup
3. core_pot_odds_equity
4. core_starting_hands
5. core_flop_play
6. core_turn_river_play
7. core_blockers_combos
8. core_equity_realization
9. core_bet_sizing_fe
10. core_gto_vs_exploit
11. core_bankroll_management
12. core_mental_game
13. core_note_taking
14. cash_rake_and_stakes
15. cash_single_raised_pots
16. cash_threebet_pots
17. cash_multiway_pots
18. cash_blind_defense
19. cash_isolation_raises
20. cash_short_handed
21. cash_population_exploits
22. mtt_antes_phases
23. mtt_short_stack
24. mtt_mid_stack
25. mtt_deep_stack
26. mtt_icm_basics
27. mtt_bubble_and_FT
28. mtt_pko_strategy
29. mtt_satellite_strategy
30. hu_preflop_strategy
31. hu_postflop_play
32. hu_exploit_adv
33. spr_basics
34. live_tells_and_dynamics
35. online_tells_and_dynamics
36. hu_preflop
37. hu_postflop
38. hu_turn_play
39. core_board_textures            (S)
40. core_river_play               (S)
41. core_check_raise_systems      (S)
42. cash_blind_vs_blind           (S)
43. cash_fourbet_pots             (S)
44. hu_river_play                 (S)
45. spr_advanced                  (A)
46. cash_multiway_3bet_pots       (A)
47. cash_delayed_cbet_and_probe_systems (A)
48. cash_overbets_and_blocker_bets (A)
49. mtt_icm_endgame_advanced      (A)
50. mtt_final_table_playbooks     (A)
51. mtt_late_reg_strategy         (A)
52. exploit_advanced              (B)
53. hand_reading_and_range_construction (B)
54. live_etiquette_and_procedures (B)
55. online_table_selection_and_multitabling (B)
56. review_workflow_and_study_routines (B)
57. donk_bets_and_leads           (B)
58. cash_squeeze_strategy         (A)
59. icm_bubble_blind_vs_blind     (A)
60. live_full_ring_adjustments    (B)
61. online_fastfold_pool_dynamics (A)
62. cash_limp_pots_systems        (A)
63. mtt_pko_advanced_bounty_routing (A)
64. mtt_day2_bagging_and_reentry_ev (A)
65. database_leakfinder_playbook  (A)
66. solver_node_locking_basics    (A)
67. live_special_formats_straddle_bomb_ante (B)
68. online_economics_rakeback_promos (B)
69. hudless_strategy_and_note_coding (B)
70. hand_review_and_annotation_standards (B)

## Verification
- Run `dart test test/content_schema_test.dart` after every content PR.
- Run `dart format . && dart analyze` before commit.
- Roadmap consistency checked manually via diff with curriculum_ids.dart.
