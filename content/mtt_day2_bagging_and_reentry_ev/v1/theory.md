What it is
Day 2 bagging and re-entry EV is end-of-flight strategy for 9-max MTTs that balances survival with chip accumulation and the option to fire again. Decisions hinge on time remaining, stack vs average, coverage (who can bust whom), and whether another flight is still open.

[[IMAGE: day2_bagging_pressure_map | Survival vs accumulation by stack vs time remaining]]
[[IMAGE: reentry_ev_heuristics | Re-entry EV ladders: buy-in, field softness, payout, bagged stack]]
[[IMAGE: end_of_day_postflop_risk | Postflop risk control near bagging: stab vs check windows]]

Why it matters
Bagging a playable stack converts chips to future EV: better table draw, antes rising, and re-entry closing. Near end of Day 1, pools polarize: some overfold, others punt to double. Re-entry availability moves thresholds: with another bullet, slightly thinner reshoves are acceptable; once closed, survival-first and variance control dominate.

Rules of thumb
- Clock awareness: with <2 orbits left and a medium stack, prioritize survival; reduce thin call-offs and avoid dominated flats OOP that invite squeezes.
- Coverage logic: when covered, prefer fold or jam trees mapped to 3bet_ip_9bb / 3bet_oop_12bb over flats; when you cover shorts, widen reshoves but still avoid multiway.
- Re-entry EV: with a bullet left and time remaining, allow slightly thinner 3bet_ip_9bb / 3bet_oop_12bb spots; when re-entry closed, keep 4bet_ip_21bb / 4bet_oop_24bb value-lean and skip marginal bluffs.
- Multiway control: from blinds versus open+call, choose 3bet_oop_12bb over call to avoid OOP side pots; IP flats are fine only when uncapped and not covered.
- Postflop near bagging: small_cbet_33 on static boards when uncapped and risk is low; half_pot_50 only to set clean commit lines with value+equity; big_bet_75 only with size_up_wet and real equity. OOP protect_check_range on middling textures.
- Delay/probe usage: delay_turn after flop checks when the turn improves your range and you are not covered; probe_turns when both checked and the turn favors you. Otherwise keep pot small.
- Exploit: tag overfold_exploit on turn nodes where pools tighten near bagging; apply pressure when you are the cover and blockers support the story.

Mini example
End of Day 1, 12 minutes left. You are CO 35bb; BTN 38bb covers; SB 20bb; BB 22bb. You open 2.2bb; BTN 3-bets to 3bet_ip_9bb. With no re-entry remaining and being covered, fold many borderline hands that were chips-EV calls earlier. Next orbit you flat IP vs HJ with 40bb each; flop K72r checks to you. Use small_cbet_33 with top pair, then plan delay_turn on bricks when you lack barreling cards; choose half_pot_50 only if the turn improves equity and sets a clean two-street commit. On wet textures, avoid big_bet_75 unless you hold strong equity (size_up_wet) and are not risking elimination to a covering stack.

Common mistakes
- Ignoring coverage and calling off vs 3-bets because "priced in."
- Flatting OOP near bagging, creating multiway side pots and hard SPRs.
- Bluff 4-betting without coverage or blockers; 4bet_ip_21bb / 4bet_oop_24bb should be value-lean.
- Autopilot c-betting and barreling on volatile boards; big_bet_75 without equity punts stacks.
- Passing on profitable pressure as the cover when pools overfold turns; mark overfold_exploit and execute with blockers.

Mini-glossary
Bagging: finishing Day 1 with a stack that advances to Day 2.
Coverage: who can bust whom; being covered increases risk premium.
Re-entry EV: value of another bullet; affects shove/call thresholds.
Side pot: chips wagered by non-all-in players that can bust you even if a short is all-in.
Commit line: planned sequence that reaches all-in with value+equity.

Contrast
Unlike standard chips-EV MTT or PKO, bagging and re-entry EV emphasize survival, coverage, and clock-based thresholds. Preflop trees skew to jam-or-fold and value-lean 4-bets; postflop lines favor control (small_cbet_33, protect_check_range, delay_turn) over thin polarization unless you safely cover opponents.

_This module uses the fixed families and sizes: size_down_dry, size_up_wet; small_cbet_33, half_pot_50, big_bet_75._
