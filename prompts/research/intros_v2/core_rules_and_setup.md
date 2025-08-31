Use TEMPLATE_v2; this doc is reference-only.

Module ID: core_rules_and_setup
Focus: Rules, hand ranking, blinds, button, action order, streets.
Must-include phrases: first_active_left_of_btn; new_total - current_bet >= last_raise_size; bettor_shows_first; first_active_left_of_btn_shows; no suit priority.
Spotkind allowlist: see prompts/dispatcher/_ALL.txt
Image placeholders: [[IMAGE: positions_table | Positions at the table]]; [[IMAGE: hand_ranking_ladder | Hand ranking ladder]]; [[IMAGE: min_raise_math_chart | Min-raise math]]
Typical online: only if you show sizes in bb.
Edge cases: min-raise and short all-in reopen; string bet vs legal single motion; out-of-turn; showdown order.
QA checklist: sections present; 450-600 words; POSITIONS only; ASCII; 1-3 images; demos 2-3; drills 12-16; valid JSONL; unique IDs.
