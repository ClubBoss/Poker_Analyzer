# Tokens & Families quick‑ref (1‑pager)

**One node → one token.** Sizes fixed: **small_cbet_33**, **half_pot_50**, **big_bet_75**. Families fixed: **size_down_dry** / **size_up_wet**.

## Choose family by texture
- **Dry/static (A83r, K72r)** → **size_down_dry** → default **small_cbet_33**.
- **Wet/dynamic (JT9ss, 986ss)** → **size_up_wet** → default **half_pot_50**.
- **Upgrade to 75%** only with blockers + Turn **Fv75** up + commitment pass (see ref).

## Allowed tokens (pick exactly one)
- **Protection / pause:** **protect_check_range**, **delay_turn**
- **Initiative after skip:** **probe_turns** *(only after chk–chk)*
- **Pressure:** **double_barrel_good** (usually 50%), **big_bet_75** *(gated)*
- **River:** **call**, **fold**, **triple_barrel_scare** *(needs scare + blockers)*
- **Preflop exploit tag:** **overfold_exploit** *(after repetition only)*

## Golden rules
- **Probe ≠ lead:** **probe_turns** only if flop went **chk–chk**.
- **No off‑tree sizes:** only 33/50/75.
- **Do not mix families:** if labeled wet, don’t default to 33.
- **Blocker + evidence gates** before 75% or thin calls.
- **Discipline on rivers:** vs **big_bet_75** without blockers → **fold** (population under‑bluffs).

*See also:* `metrics_mini_glossary`, `spr_commitment_quickref`.
