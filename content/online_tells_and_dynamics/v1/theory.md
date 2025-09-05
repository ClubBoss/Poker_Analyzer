What it is
This module translates online timing, sizing, and sequence reads into a stable action set you can execute without changing your trees. You will take soft signals like snap actions, tank-then-small bets, merged versus polar sizing, and chk-chk sequences, then map them to: 3bet_ip_9bb, 3bet_oop_12bb, 4bet_ip_21bb, 4bet_oop_24bb, small_cbet_33, half_pot_50, big_bet_75, size_up_wet, size_down_dry, protect_check_range, delay_turn, probe_turns, double_barrel_good, triple_barrel_scare, call, fold, overfold_exploit.

[[IMAGE: online_timing_map | Common timing patterns and likely hand classes]]
[[IMAGE: online_size_patterns | Sizing families and exploit paths]]
[[IMAGE: online_flow_chart | From read -> tokenized action]]

Why it matters
Online pools show repeatable patterns: autopilot range-bets on static flops, under-4-betting at 100bb, fast folds to 3-bets, and under-bluffed polar rivers. These reads shift frequencies, not physics. You still use size_down_dry on static boards and size_up_wet on dynamic ones, but you change how often you press each token to capture EV without adding new sizes.

Rules of thumb
- Timing: snap small_cbet_33 often signals range-bet autopilot; why: pre-decided actions appear faster and are wider. Respond by defending correctly now and probe_turns when the flop checks through.
- Sizing: half_pot_50 is usually merged, big_bet_75 is polar; why: population selects bigger sizes with nuts or air and medium sizes with many middling hands. Versus overfolds to big sizes, combine size_up_wet with big_bet_75; versus sticky callers, value with half_pot_50.
- Sequence: chk-chk often caps ranges; why: many players miss value or fear raises. Favor probe_turns or double_barrel_good on good turns. If villains raise turns aggressively, delay_turn with medium strength.
- Preflop: versus fast-fold blinds and under-4-betting, widen 3bet_oop_12bb and tag overfold_exploit; why: immediate folds raise bluff EV and lower 4-bet risk. Against iso wars at 15–40bb, 3bet_ip_9bb with blockers; versus 4-bet-happy opponents, tighten or 4bet_ip_21bb / 4bet_oop_24bb with premiums.
- Rivers: population under-bluffs big_bet_75; why: they lack natural bluffs and avoid thin polar bets. Without blockers, fold; with strong blockers on scare cards, consider triple_barrel_scare.

[[IMAGE: online_board_context | Texture still drives size family selection]]

Mini example
HU 100bb. SB opens 2.0bb; BB calls (pot ~6bb). Flop A83r. SB snap-bets 2bb (small_cbet_33) — read: autopilot range bet (wide). BB defends standard now. Later, on boards that check through (e.g., T73r → 9s), BB favors probe_turns.  
Preflop dynamic read: pool fast-folds vs 12bb and under-4-bets — BB widens 3bet_oop_12bb with blockers (overfold_exploit). Postflop, keep sizes in-family: size_down_dry on dry flops, size_up_wet + big_bet_75 on dynamic turns where tanks precede overfolds.

Common mistakes
- Treating reads as rules. Error: single datapoints are noisy and create false exploits; why players do it: overweight recency. Fix: require repetition before tagging overfold_exploit.
- Changing sizes off-tree. Error: inventing new bet sizes increases complexity and leaks; why players do it: chasing tiny edges. Fix: keep small_cbet_33, half_pot_50, big_bet_75 and shift frequencies.
- Never protecting checks. Error: capped checks get farmed by probes and raises; why players do it: fear of free cards. Fix: protect_check_range with some strong hands and delay_turn with medium strength.

Mini-glossary
Snap: very fast action, often pre-decided with a wide or capped range.  
Tank-then-small: delay followed by small bet; commonly merged, medium strength.  
Merged vs polar: half_pot_50 targets many middling hands; big_bet_75 targets nuts or air.  
Autopilot: habitual action regardless of hand; exploit with probe_turns or well-timed double_barrel_good.

Contrast
Math and solver modules define prices and baselines; this module converts online timing and sizing dynamics into the same token actions without inventing new trees.
