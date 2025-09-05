What it is
This module upgrades SPR (stack-to-pot ratio) from a definition to a planning tool. You will map preflop ladders to target SPR bands, let texture pick the size family, then choose lines inside that family using commitment thresholds and blockers. You keep exactly the same tokens and sizes used everywhere else: 3bet_ip_9bb, 3bet_oop_12bb, 4bet_ip_21bb, 4bet_oop_24bb, small_cbet_33, half_pot_50, big_bet_75, plus the concepts size_down_dry / size_up_wet, protect_check_range, delay_turn, probe_turns, double_barrel_good, triple_barrel_scare, call, fold, overfold_exploit. No new sizes or trees. HU-first, transferable to 6-max BvB/SRP/3BP.

Why it matters
The same ladders (9/12/21/24) set predictable SPR bands that simplify decisions before cards arrive. Reverse SPR via 4-bets creates clean commitment points; mid-SPR highlights where to avoid raise wars; high SPR after chk-chk creates profitable probe windows. Using SPR to pre-plan lines lowers error rate more than tiny mix tweaks. The physics rule remains: texture selects the size family; SPR shifts frequency and line selection within that family.

Rules of thumb

* Reverse SPR with 4-bets: 4bet_ip_21bb and 4bet_oop_24bb create clean, low SPR. Trim thin OOP flats. Why: clearer realization and fewer messy turn trees.
* Low SPR + dynamic turn: start half_pot_50; upgrade to big_bet_75 only with strong blockers and proven fold‑vs‑75 spikes (size_up_wet). Why: leverage works when you block value and they overfold.
* Turn → river planning: if turn big_bet_75 leaves trivial behind, commit only with equity/blockers; otherwise stay with half_pot_50 or delay_turn. Why: avoid bloating pots with hands that cannot finish the tree.
* Mid SPR OOP vs raise‑prone IP: increase delay_turn and keep protect_check_range. Why: you realize equity and dodge high‑frequency turn raises.
* High SPR after check‑check: increase probe_turns on favorable turns. Why: many opponents surrender after missing the flop stab.
* Low SPR ≠ auto‑call: fold vs polar big_bet_75 without blockers in under‑bluffed pools. Why: population effect beats price.
* Ladder → plan mapping: 3bet_oop_12bb and 3bet_ip_9bb lower SPR so that top pairs and initiative gain. On static boards prefer size_down_dry with small_cbet_33; on dynamic boards start half_pot_50 and double_barrel_good only with equity/blockers. Why: initiative plus lower SPR improves conversion.
* BvB transfer: blind‑defend trees shift SPR fast; flop donk/turn lead intersections exist, but sizes remain 33/50/75. Why: initiative may flip while families stay identical.
* Exploit gates: tag overfold_exploit only with persistent evidence; SPR never justifies off‑tree plays. Why: discipline controls variance and bias.

[[IMAGE: spr_commitment_planner | Turn sizing -> river plan at varying SPR]]
[[IMAGE: ladder_to_spr_map | 9/12/21/24 ladders -> typical SPR bands]]
[[IMAGE: spr_texture_matrix_advanced | Texture×SPR with blocker gates]]

Mini example
HU 100bb. SB opens 2.0bb, BB 3bet_oop_12bb (lower SPR). Flop A83r (static): choose size_down_dry with small_cbet_33. Turn 7c (still dry): prefer half_pot_50 only when equity/backdoors justify; against raise‑prone IP, delay_turn with medium strength.

Second line: BTN faces CO 3‑bet; BTN 4bet_ip_21bb to create reverse SPR. Flop K72r (static) -> small_cbet_33. Turn Qs (connectivity rises): with strong blockers, double_barrel_good using half_pot_50; if big_bet_75 would leave trivial behind *and* fold‑vs‑75 is high, upgrade; otherwise keep half_pot_50 and plan river discipline.

River discipline: facing polar big_bet_75 on a scare card without blockers -> fold. As PFA on a missed runout with top‑tier blockers -> triple_barrel_scare.

Common mistakes

* Treating low SPR as auto‑stack with any pair. Fix: fold rivers vs polar big_bet_75 without blockers in under‑bluffed pools.
* Engineering off‑tree sizes to force shoves. Fix: plan within 33/50/75; commit via big_bet_75 only when it leaves trivial behind and blockers support it.
* Over‑bluffing static high‑SPR rivers. Fix: prefer size_down_dry thin value earlier, and call/fold discipline on river.
* Calling too wide OOP at mid SPR. Fix: prefer delay_turn and protect_check_range over marginal continues.
* Ignoring probe equity at high SPR after check‑check. Fix: add probe_turns on favorable cards.
* Confusing texture with SPR. Fix: physics first (family by texture), then SPR adjusts frequency/line choice.

Mini-glossary
SPR: stack‑to‑pot ratio at street start guiding leverage and commitment.
Reverse SPR: setting a low, clean SPR via 4‑bets for simpler decisions.
Commitment threshold: point where turn sizing makes river shove trivial.
Leverage: pressure relative to stacks created by your bet size.
Realization: how efficiently equity converts to EV given position and SPR.

Contrast
spr_basics introduced families by texture and simple SPR nudges. This module goes deeper: ladder‑to‑plan mapping, blocker‑gated upgrades, and turn sizing that pre‑plans river outcomes — all inside the same tokens and 33/50/75 families.
