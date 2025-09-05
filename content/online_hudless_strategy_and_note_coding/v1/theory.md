What it is
HUD-less strategy uses compact notes and population priors to convert timing, sizing, and sequence cues into frequency shifts with a fixed action set: 3bet_ip_9bb, 3bet_oop_12bb, 4bet_ip_21bb, 4bet_oop_24bb, small_cbet_33, half_pot_50, big_bet_75, size_up_wet, size_down_dry, protect_check_range, delay_turn, probe_turns, double_barrel_good, triple_barrel_scare, call, fold, overfold_exploit. Physics first: texture picks size family (size_down_dry on A83r/K72r; size_up_wet on JT9ss/986ss). Reads only change frequencies.

Why it matters
Online anonymity, short samples, and table churn weaken stats. A robust note code prevents guesswork, keeps ladders fixed (9/12/21/24), and preserves 33/50/75 families. You act on repeated signals, not one-off hands, and map every read to tokens without inventing sizes.

Rules of thumb

* Tag taxonomy: PF Fv3B up, 4B down; FL x/r low; TR FvProbe up; TR Fv75 up; RV Polar low; Seq chk-chk often; Timing snap 33; Timing tank->small merged.
* Repetition tiers: weak(1-2), medium(3-5), strong(6+). Act conservatively at weak; escalate at medium+ when texture fits the plan.
* PF Fv3B up + 4B down -> widen 3bet_oop_12bb and 3bet_ip_9bb with blockers; add 4bet_ip_21bb for premiums. Why: folds and low 4-bets raise EV of value and blocker-driven pressure.
* Seq chk-chk often + TR FvProbe up -> probe_turns. Why: pooled surrender after missed c-bet.
* TR Fv75 up on dynamic cards -> double_barrel_good with big_bet_75 (size_up_wet) when you hold blockers. Why: larger size exploits elevated folds and taxes draws.
* FL x/r low on static -> small_cbet_33 with size_down_dry at high frequency. Why: safe denial and equity realization.
* RV Polar low -> fold without blockers; versus merged small bets prefer half_pot_50 for value. Why: under-bluffed big bets; merged calls pay.
* Stabby vs checks -> protect_check_range and add delay_turn with medium strength. Why: avoid auto-profit stabs and control variance.
* Timing snap 33 on dry -> prefer size_down_dry small_cbet_33 thin value; Timing tank->small merged -> reduce bluff-raises; continue with call or fold by blockers. Why: timing hints merge vs polar.
* Overfold_exploit tag only when evidence persists and matches texture (e.g., repeated fast folds to 12bb, fold spikes vs 75% on wet turns). Why: avoid overfitting.
* Sizes never change. Only frequency shifts within small_cbet_33, half_pot_50, big_bet_75 and fixed preflop ladders.

[[IMAGE: hudless_tags_grid | Minimal HUD-less tag codes mapped to actions]]
[[IMAGE: signal_to_token_flow | From live read -> frequency shift -> token]]
[[IMAGE: confidence_tiers | Weak/Medium/Strong repetition lanes]]

Mini example
PF: you tag BTN “Fv3B up, 4B down”. Next orbit at 100bb, BB widens 3bet_oop_12bb with A5s; with AKs IP facing 12bb you choose 4bet_ip_21bb. SRP K72r checks through; on 3h turn your “FvProbe up” tag maps to probe_turns. On JT9ss, your “Fv75 up” tag maps to big_bet_75 as double_barrel_good with blockers. River A94r-6s-Kd, “Polar low” tag -> fold marginal bluff-catchers without blockers.

Common mistakes

* Overfitting one hand. Fix: require repetition tiers and texture fit before exploits.
* Writing novels, not tags. Fix: use short codes tied to tokens.
* Off-tree sizing. Fix: stick to 33/50/75 and ladders; adjust frequency only.
* Ignoring texture. Fix: size_down_dry on static, size_up_wet on dynamic.
* Hero-calling polar rivers. Fix: fold without blockers; reserve calls for strong blockers.
* Failing to protect checks. Fix: protect_check_range and add delay_turn.

Mini-glossary
Snap: instant action, often pre-decided, range or merged.
Tank-then-small: delayed small bet; commonly merged strength.
Fv3B: fold vs 3-bet; high invites blocker 3-bets and value 4-bets.
FvProbe: fold vs turn probe after flop checks; high invites probe_turns.
Polar/Merged: big_bet_75 polar vs half_pot_50 merged value.
Population prior: default pool tendencies used when no HUD data.
Tag tiering: weak/medium/strong repetition lanes guiding action.
Exploit tracker: your running list of tags linked to tokens.

Contrast
“online_hud_and_db_review” is stats-driven; “online_notes_and_exploit_tracker” is a fuller system. Here you operate with no HUD, using ultra-light tags and the same fixed tokens and sizes.
