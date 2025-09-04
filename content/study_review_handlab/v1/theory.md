What it is
This module is a repeatable study pipeline that turns played hands into stable, tokenized adjustments. Steps: collect hands → tag quick signals → pick review spots → run a compact solver baseline (preflop ladders and 33/50/75 only) → optional single‑variable node lock → convert outputs to tokens → build drills → track KPIs → close the loop next session. All actions stay within: 3bet_ip_9bb, 3bet_oop_12bb, 4bet_ip_21bb, 4bet_oop_24bb, small_cbet_33, half_pot_50, big_bet_75, size_up_wet, size_down_dry, protect_check_range, delay_turn, probe_turns, double_barrel_good, triple_barrel_scare, call, fold, overfold_exploit.

[[IMAGE: study_pipeline_map | From hand import -> tag -> solver -> token]]
[[IMAGE: kpi_review_dashboard | Weekly KPIs and leak radar]]
[[IMAGE: hand_to_drill_flow | How a spot becomes a spaced drill]]

Why it matters
Systemized review improves EV/hour far more than ad‑hoc browsing. A single compact tree produces consistent decisions under pressure: physics first (board texture picks the size family), reads second (frequency shifts). The loop converts insights into drills and KPIs so they survive into real play and scale to more tables without inventing new sizes.

Rules of thumb
* Hand collection: mark hands in‑play; export HU SRP and 3‑bet pots, dynamic turns (draw‑completing), and polar rivers. Why: these nodes drive EV and mistakes repeat.
* Triage spots: prioritize price mistakes (pot odds), size misuse (small_cbet_33 vs half_pot_50 vs big_bet_75), and river blocker errors. Why: biggest and most frequent leaks.
* Tree discipline: preflop ladders stay 3bet_ip_9bb / 3bet_oop_12bb / 4bet_ip_21bb / 4bet_oop_24bb; postflop sizes are 33/50/75 only. Why: stable comparisons and legible EV deltas.
* Baseline first: read EV edges, not only frequencies; allow small EV mixes. Why: you execute the highest‑EV token, not the loudest heatmap color.
* Node‑locking basics: lock one knob (e.g., Fold vs Turn 75%) and sweep plausible values; adopt only if EV gains persist → tag overfold_exploit. Why: avoids overfitting to noise.
* Texture rule: size_down_dry on A83r, K72r; size_up_wet on JT9ss, 986ss. Why: physics before reads; locks change fold rates, not textures.
* Token mapping: wet turn + higher Fold vs 75% → double_barrel_good with big_bet_75; under‑bluffed polar river → fold without blockers; check‑check then surrender → probe_turns; frequent stabs → protect_check_range or delay_turn. Why: clean translation from finding to action.
* Drill building: each reviewed hand produces one demo and one drill with the exact token and a one‑line rationale. Why: retention and spaced repetition.
* KPI loop: weekly counts for missed probe_turns after check‑check, thin value misses (size_down_dry), overuse of big_bet_75 on dry boards, river calls without blockers, and skipped 4bet_ip_21bb with premiums. Why: track what moves EV.
* Session guardrails: under fatigue or when scaling tables, bias toward small_cbet_33, half_pot_50, delay_turn, protect_check_range; reserve big_bet_75 for clear blocker‑supported folds. Why: reduces error rate while preserving EV.

Mini example
Flagged hand 1: HU 100bb, SRP K72r IP. Baseline: size_down_dry → small_cbet_33 at high frequency; EV gap to check is small, so some mixing is fine. Turn 3h: database shows elevated turn‑raise%; choose delay_turn more with medium Kx to avoid getting raised off equity. River on Qc: facing big_bet_75 without helpful blockers is a fold; with better blockers, call more.
Flagged hand 2: HU 60bb, 3‑bet pot JT9ss OOP after 3bet_oop_12bb. Baseline: size_up_wet prefers pressure; lock sweep shows Fold vs Turn 75% rises on straightening turns, so double_barrel_good with big_bet_75 increases EV. If the lock advantage persists across reasonable ranges, tag overfold_exploit for this texture family.
Conversion: For each case, create a drill: (i) choose size family by texture, (ii) pick the continuation token, (iii) add one KPI tick (e.g., “missed probe_turns” if you failed to stab after check‑check).

Common mistakes
* Overbuilt trees with too many sizes. Fix: ladders + 33/50/75 only.
* Multi‑lock spaghetti. Fix: lock one variable, sweep a band, adopt only persistent EV gains.
* Reading frequency without EV context. Fix: select the highest‑EV token and allow small mixes when deltas are tiny.
* Inventing off‑tree sizes. Fix: stay with small_cbet_33, half_pot_50, big_bet_75.
* Skipping blockers on rivers. Fix: fold more to polar big bets without blockers; triple_barrel_scare only with strong blockers on credible scare cards.
* Ignoring realization. Fix: call thresholds rise OOP; prefer initiative or fold marginal spots instead of “close” calls.

Mini-glossary
Baseline: the unlocked equilibrium for your compact tree.
Node lock: fixing one opponent behavior (e.g., fold vs 75%) to test a counter‑strategy.
Lock sweep: testing several realistic lock values to see if EV gains persist.
KPI: weekly count of key decisions (missed probes, thin value, river calls w/o blockers).
Drill: one‑line question with a single token answer built from a reviewed spot.
Token set: the fixed actions used in training and execution (preflop ladders, 33/50/75, and concepts).

Contrast
math_solver_basics teaches reading a baseline; solver_node_locking_basics teaches running locks. This module unifies both into a weekly workflow that outputs drills and KPI targets while preserving the same token set and size families.
