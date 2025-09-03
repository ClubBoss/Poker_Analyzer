What it is
ICM bubble blind-vs-blind is SB vs BB near the money bubble in 9-max MTTs. Coverage (who can bust whom) and risk premium change incentives: the covered player must avoid stack-offs without strong equity, while the cover can pressure more. Chip-EV lines shrink; cash-EV rules dominate.

[[IMAGE: icm_bubble_bvb_pressure_map | Coverage & risk premium SB vs BB across stacks]]
[[IMAGE: bvb_preflop_ladders_icm | SB/BB jam & call ladders by stacks/coverage]]
[[IMAGE: bvb_postflop_risk_control | Postflop pressure vs control windows under ICM]]

Why it matters
On the bubble, chips lost hurt more than chips won help. SB and BB battle every orbit, so mistakes get magnified: loose call-offs when covered torch equity, and timid pressure when you cover leaves seats on the table. Clean preflop trees and low-risk postflop lines protect stack equity and convert population overfolds.

Rules of thumb
- Roles and coverage: when you cover, widen opens and 3-bets; BB prefers 3bet_oop_12bb over flats. When covered, tighten call-offs and avoid dominated OOP peels. Why: coverage flips risk premium and fold equity.
- Stack bands: 8-15bb jam-first trees dominate (SB maps to 3bet_ip_9bb, BB to 3bet_oop_12bb); 16-25bb mix raise-fold and reshove; 26-40bb add small opens and selective 3-bets with postflop discipline. Why: lower SPR and ICM penalties punish thin flats and loose defends.
- Value-lean 4-bets only: under ICM, keep 4bet_oop_24bb (and 4bet_ip_21bb when applicable) for strong value; avoid bluff 4-bets. Why: call-off thresholds rise when covered, so bluffs burn cash equity.
- Postflop defaults: small_cbet_33 on static Axx/Kxx when uncapped; half_pot_50 to set clean two-street commits with value plus equity; big_bet_75 only with nut advantage and real equity. OOP on middling textures, protect_check_range. Why: smaller, clear sizes manage exposure yet pressure capped ranges.
- Timing and exploits: delay_turn and probe_turns only when the turn meaningfully shifts ranges and risk is acceptable. As cover, double_barrel_good on range turns using half_pot_50 and reserve triple_barrel_scare for credible rivers with blockers. Tag overfold_exploit where covered mediums fold turns. Why: pools overfold to pressure they cannot profitably call.
- Geometry: plan flop+turn to avoid marginal river call-offs when covered; keep commitment math clean.

Mini example
Orbit 1: UTG, MP, CO, BTN fold. SB 32bb covers BB 21bb; SB opens small, BB 3bet_oop_12bb. SB folds KTo; continue AQ/TT+ and 4bet_oop_24bb for pure value.
Orbit 2: CO opens, BTN folds, SB 24bb covered completes; BB checks. Flop J95r, SB protect_check_range, BB checks back. Turn Qx improves IP; BB delay_turn half_pot_50.
Orbit 3: BTN folds; next hand SB min-raises vs BB who covers. BB prefers 3bet_oop_12bb over flat. On A72r, BB small_cbet_33; on safe turn, half_pot_50 as a commit step.

Common mistakes
- Flatting OOP as the covered player and creating low-SPR guesswork. Why it is a mistake: you face tough turn decisions with dominated hands. Why it happens: fear of folding preflop.
- Calling reshoves too wide when covered. Why it is a mistake: chip-EV habits ignore ICM risk premium. Why it happens: anchoring to pre-bubble charts or being “priced in.”
- Vanity big_bet_75 on wet boards without equity. Why it is a mistake: you polarize but cannot defend raises when covered. Why it happens: overestimating fold equity and nut share BvB.

Mini-glossary
Coverage: who can bust whom; being covered increases your risk premium.
Risk premium: extra equity required to continue because busting costs payout equity.
Jam proxy: mapping shove or reshove to 3bet_ip_9bb (SB) or 3bet_oop_12bb (BB) for clarity.

Contrast
Unlike standard BvB chip-EV play, bubble BvB prioritizes coverage-first pressure, tighter call-offs when covered, and small-cbet plus half-pot commit trees over thin polarization.
