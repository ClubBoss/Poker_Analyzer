# Metrics mini-glossary (1‑pager)

**Purpose.** Define a few pool metrics and how they translate into the fixed tokens and 33/50/75 families. Evidence gates first; no new sizes or trees.

## Core metrics → token routes
- **Fv3Bet (Fold vs 3‑bet).** High across samples → widen **3bet_ip_9bb** / **3bet_oop_12bb** with blockers; after persistence, tag **overfold_exploit**. Low 5‑bets → value **4bet_ip_21bb** / **4bet_oop_24bb**.
- **Turn Fv75 (Fold vs 75% on turn).** High + strong blockers → upgrade to **big_bet_75** as **double_barrel_good**. If missing either, stay **half_pot_50** or **delay_turn**.
- **Fv50 (Fold vs 50% on turn).** Elevated → **half_pot_50** gains immediate EV; only upgrade to 75 when Turn Fv75 is also up + blockers.
- **Fold vs Probe (after chk–chk flop).** High → take **probe_turns** on good cards. Never probe without the chk–chk sequence.
- **AFq turn / xr turn (turn aggression / check‑raise).** High → raise‑risk ↑ → favor **delay_turn** with medium strength and add **protect_check_range** earlier.
- **River polar bluff rate proxy.** If database shows under‑bluffed big rivers, default **fold** vs **big_bet_75** without blockers; with scare + premium blockers + plan → **call** or **triple_barrel_scare** as PFA.

## Reading rules (fast)
- **Evidence gate:** adopt exploits only at repetition tier **medium+ (3–5+)**. Single hands = noise.
- **Blocker gate:** large bets (**big_bet_75**) and thin river calls require value‑removing blockers.
- **Family first:** static → **size_down_dry** → **small_cbet_33**; dynamic → **size_up_wet** → **half_pot_50**.

## Quick mapping
- Fv3Bet ↑ + 5‑bet ↓ → 3bet ladder ↑ (with blockers) → *overfold_exploit* tag after persistence.
- Fold vs Probe ↑ + chk–chk → **probe_turns**.
- Turn Fv75 ↑ + blockers + commitment pass → **big_bet_75**; else **half_pot_50** / **delay_turn**.
- AFq/xr turn ↑ → **delay_turn**; earlier **protect_check_range**.
- Under‑bluffed polar rivers → **fold** w/o blockers; with blockers + plan → **call**/**triple_barrel_scare**.

*See also:* `tokens_and_families_quickref`, `spr_commitment_quickref`.
