# SPR commitment quick‑ref (1‑pager)

**Goal.** Decide whether a turn bet commits you to many rivers while keeping sizes at **33/50/75**.

## SPR bands (after flop, before turn)
- **High (≥3):** prefer **half_pot_50** or **delay_turn**; 75% only with nuts + blockers.
- **Mid (1.5–3):** main decision band → apply **all 3 gates** before **big_bet_75**.
- **Low (≤1.5):** commitment is easy, but still require blockers before polarizing.

## Gates for 50 → 75 (all required)
1) **Blockers** to top value / strong draws.  
2) **Evidence:** Turn **Fv75** up (log / DB / stable read).  
3) **Commitment gate:** 75% on turn must **not** force bad river jams with weak equity.  
   → If any gate fails: stay **half_pot_50** or **delay_turn**.

## River plan discipline
- Versus polar **big_bet_75** without blockers → **fold**.
- As PFA on scare with premium blockers and a pre‑built plan → **triple_barrel_scare**; else **call** only with blockers + evidence.

## Micro‑checklist (before pressing “75%”)
- [ ] Texture labeled? (**size_up_wet** / **size_down_dry**)
- [ ] SPR band noted? (High / Mid / Low)
- [ ] Blockers present?
- [ ] Turn **Fv75** evidence?
- [ ] Commitment gate passes? (river not forced / equity sufficient)

*See also:* `metrics_mini_glossary`, `tokens_and_families_quickref`.
