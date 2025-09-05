What it is
Advanced ICM endgame covers bubble, pre-FT jumps, and full FT down to 3-handed. Chips do not equal cash; busting is costly. Coverage asymmetry rules: big stacks apply pressure, medium stacks carry the highest risk premium, and short stacks choose clean shove/call-off trees.

[[IMAGE: icm_endgame_pressure_map | Risk premium by stack/position (bubble, FT 9->3, 3–5 handed)]]
[[IMAGE: endgame_shove_call_ladders | Shove/reshove/call-off ladders by seat and coverage]]
[[IMAGE: endgame_postflop_geometry | SPR control and risk exposure at FT]]

Why it matters
Pay jumps change good chips-EV plays into bad cash-EV plays. Calling off when covered requires more equity; thin peels OOP are punished. Clear jam-first trees simplify decisions, avoid dominated multiway spots, and let you leverage coverage with credible pressure.

Rules of thumb
- Roles: big stacks pressure wide opens, 3-bet/jam more; medium stacks tighten call-offs and avoid flats OOP; short stacks time shove spots and avoid fancy postflop.
- Preflop: favor jam/reshove proxies 3bet_ip_9bb and 3bet_oop_12bb over flats when covered. Keep 4bet_ip_21bb and 4bet_oop_24bb value-lean; bluff 4-bets rare unless you cover and hold top blockers.
- Coverage: when covered, fold more to jams and large sizings; when you cover, widen steals and reshoves, especially BTN/SB vs blinds.
- Squeeze: squeeze as the cover versus open+caller; cold-calling OOP when covered creates bad SPR and dominated ranges.
- Postflop: small_cbet_33 on safe, static boards when uncapped; protect_check_range more OOP. Use half_pot_50 only with value+equity to set clean commit lines; big_bet_75 requires size_up_wet equity or nut advantage.
- Timing: delay_turn and probe_turns selectively; reduce bluff rate when covered. As the cover, plan double_barrel_good on range turns and only triple_barrel_scare on credible rivers with blockers.
- Exploit: mediums overfold turns to covering stacks - tag overfold_exploit on those nodes.

Mini example
Bubble, 9-max. CO 36bb (covered by BTN 62bb) opens 2.2bb. BTN uses 3bet_ip_9bb (jam-proxy) with A5s: blockers + coverage. CO folds KJo that might defend in chips-EV. Later at FT, SB 24bb (covered by BB 55bb) opens 2.1bb; BB reshoves 3bet_oop_12bb with AJo and SB folds dominated. Postflop, CO defends vs CL 3-bet; on K72r the CL uses small_cbet_33, then half_pot_50 on a range-shifting turn (double_barrel_good). On river A with blockers, CL may triple_barrel_scare; without, protect_check_range earlier and abort.

Common mistakes
- Calling off because a spot is barely chips-EV while covered. Fold and keep ladder equity.
- Cold-calling OOP medium stack to “see a flop.” Prefer 3bet_oop_12bb jam-proxy or fold.
- Vanity big_bet_75 without equity or nut advantage. Half-pots only when setting a clean commit.
- Bluff 4-betting tight 3-bettors under ICM. Keep 4bet_ip_21bb and 4bet_oop_24bb value-lean.
- Triple-barreling scare cards without blockers or coverage edge; story collapses and burns cash equity.

Mini-glossary
Risk premium: extra equity required to continue because busting loses payout equity.
Covered/Cover: opponent has you covered / you cover them; shifts who should risk chips.
3bet_ip_9bb / 3bet_oop_12bb: jam/reshove family proxies to simplify endgame trees.
4bet_ip_21bb / 4bet_oop_24bb: value-lean 4-bet families under ICM.
small_cbet_33 / half_pot_50 / big_bet_75: turn/river size families.
protect_check_range / delay_turn / probe_turns: low-risk lines to control exposure.
overfold_exploit: pool tendency to overfold turns when pressure and coverage align.

Contrast
Compared to chips-EV deep-stack play, advanced ICM endgame favors jam-first preflop, tighter call-offs when covered, fewer bluffs, and pressure timed by coverage and blockers rather than pure equity.

_This module uses the fixed families and sizes: size_down_dry, size_up_wet; small_cbet_33, half_pot_50, big_bet_75._
