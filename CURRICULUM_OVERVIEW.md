Полный список из 81 блока обучения с краткими пояснениями.  
Назначение: обзор для внешних читателей и новичков.  
Источники контента: theory.md / demos.jsonl / drills.jsonl в паке каждого модуля.  
Примечание: режим Live overlay накладывает лайв-контекст на Cash/MTT без дублирования деревьев.

---

## Core
1. core_rules_and_setup — Правила, порядок действий, шоудаун.
2. core_positions_and_initiative — Позиции и инициатива.
3. core_pot_odds_equity — Пот-оддсы и эквити.
4. core_starting_hands — Базовые стартовые диапазоны.
5. core_flop_fundamentals — Фундамент флопа и c-bet.
6. core_turn_fundamentals — Игровые планы на тёрне.
7. core_river_fundamentals — Ривер: вэлью/блеф/частоты.
8. core_board_textures — Категории досок и стратегии.
9. core_equity_realization — Реализация эквити в линии.
10. core_bet_sizing_fe — Сайзинги и fold equity.
11. core_check_raise_systems — Чек-рейз как система.
12. core_gto_vs_exploit — Баланс GTO и эксплойт.
13. core_bankroll_management — Банкролл и риски.
14. core_mental_game — Рутины фокуса и антитильт.
15. core_note_taking — Нотсы, теги, структура записей.

## Cash
16. cash_rake_and_stakes — Рейк/лимиты и выбор столов.
17. cash_single_raised_pots — SRP: префлоп+постфлоп.
18. cash_threebet_pots — 3-бет банки.
19. cash_fourbet_pots — 4-бет банки.
20. cash_multiway_pots — Мультивей-план.
21. cash_multiway_3bet_pots — Мультивей 3-бет.
22. cash_blind_defense — Защита блайндов.
23. cash_blind_vs_blind — SB vs BB.
24. cash_isolation_raises — Изоляции против лимпов.
25. cash_squeeze_strategy — Сквизы.
26. cash_short_handed — 6-max и короткие составы.
27. cash_population_exploits — Эксплойты против поля.
28. cash_limp_pots_systems — Системы для лимп-потов.
29. cash_delayed_cbet_and_probe_systems — Delayed/probe.
30. cash_overbets_and_blocker_bets — Овербеты/блокер-беты.

## MTT
31. mtt_antes_phases — Фазы с анте.
32. mtt_short_stack — Короткий стек.
33. mtt_mid_stack — Средний стек.
34. mtt_deep_stack — Дипстек.
35. mtt_icm_basics — База ICM.
36. mtt_icm_endgame_advanced — ICM эндгейм продвинуто.
37. mtt_pko_strategy — PKO базовые принципы.
38. mtt_pko_advanced_bounty_routing — PKO баунти-роутинг.
39. mtt_satellite_strategy — Сателлиты.
40. mtt_day2_bagging_and_reentry_ev — Бэггинг и ребаи EV.
41. mtt_final_table_playbooks — Плейбуки финалки.
42. mtt_late_reg_strategy — Лейт-рег.
43. icm_bubble_blind_vs_blind — Баббл BvB (ICM).

## Heads-Up
44. hu_preflop — Практика префлопа.
45. hu_postflop — Практика постфлопа.
46. hu_turn_play — Тёрн в HU.
47. hu_river_play — Ривер в HU.
48. hu_preflop_strategy — Диапазоны HU префлоп.
49. hu_postflop_play — Стратегия HU постфлоп.
50. hu_exploit_adv — Продвинутые эксплойты в HU.

## Math
51. math_intro_basics — Введение в математику покера.
52. math_pot_odds_equity — Пот-оддсы/эквити расчёты.
53. math_combo_blockers — Комбинаторика/блокеры.
54. math_ev_calculations — EV-вычисления.
55. math_icm_basics — База ICM-математики.
56. math_icm_advanced — Продвинутые ICM-модели.
57. math_solver_basics — Базовая работа с солвером.
58. solver_node_locking_basics — Node locking базово.

## Cross / Online dynamics
59. online_tells_and_dynamics — Онлайн-теллы и паттерны.
60. online_table_selection_and_multitabling — Селект и МТТинг.
61. online_fastfold_pool_dynamics — Динамика fastfold.
62. online_economics_rakeback_promos — Экономика/рейкбек.
63. hudless_strategy_and_note_coding — Без HUD: код нотсов.
64. exploit_advanced — Продвинутые эксплойты.
65. donk_bets_and_leads — Донк и лид.
66. spr_basics — База SPR.
67. spr_advanced — Продвинутый SPR.
68. hand_review_and_annotation_standards — Стандарты разбора.
69. review_workflow_and_study_routines — Рутины обучения.
70. database_leakfinder_playbook — Ликфайндер в базе.

## Live overlay (режим поверх Cash/MTT)
71. live_tells_and_dynamics — Теллы, контекст, надёжность.
72. live_etiquette_and_procedures — Этикет и процедуры.
73. live_full_ring_adjustments — Адаптации фулл-ринг.
74. live_special_formats_straddle_bomb_ante — Стрэддл/бомб-анте.
75. live_table_selection_and_seat_change — Выбор стола/пересадка.
76. live_chip_handling_and_bet_declares — Фишки и объявления ставок.
77. live_speech_timing_basics — Речь/тайминг за столом.
78. live_rake_structures_and_tips — Рейк, тайм-коллы, чаевые.
79. live_floor_calls_and_dispute_resolution — Флоор-коллы и споры.
80. live_session_log_and_review — Журнал лайв-сессий и разбор.
81. live_security_and_game_integrity — Безопасность и честность игры.

### Как работает Live overlay
- Тумблер Live overlay включает лайв-контекст для Cash/MTT.  
- Добавляются флаги сценариев: has_straddle, bomb_ante, multi_limpers, announce_required, rake_type(time|drop), avg_stack_bb, table_speed.  
- Активируются валидаторы процедур: string_bet, single_motion_raise_legal, bettor_shows_first, first_active_left_of_btn_shows.  
- Структура модулей и SpotKind не дублируются.

## Next after Core: High-priority backlog (append-only)

- cash_3bet_ip_playbook — 3-bet pots IP playbook. Track: Cash. Level: L3–L4.
- cash_3bet_oop_playbook — 3-bet pots OOP playbook. Track: Cash. Level: L3–L4.
- cash_blind_defense_vs_btn_co — Blind defense vs BTN/CO. Track: Cash. Level: L3.
- cash_turn_river_barreling — Double/triple barrel maps. Track: Cash. Level: L3–L4.
- icm_mid_ladder_decisions — Mid-ladder decisions. Track: MTT/ICM. Level: L4–L5.
- icm_final_table_hu — Final table HU play. Track: MTT/ICM. Level: L4–L5.
- online_population_exploits_playbook — Online pool exploits → tokens. Track: Online. Level: L3–L4.
- spr_commitment_checklists — SPR commitment checklists. Track: Cross. Level: L3.

