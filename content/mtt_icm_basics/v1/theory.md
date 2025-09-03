What it is
ICM (Independent Chip Model) means chips do not equal cash. Busting costs future payout equity, so calling off requires more equity than in chips-EV. Risk premium is highest for medium stacks near pay jumps, lower for big stacks who cover, and moderate for shorts who are often forced to take spots.

[[IMAGE: icm_pressure_map | Risk premium by stacks/positions (bubble, pre-FT, FT)]]
[[IMAGE: icm_calloff_ladders | Shove/call-off ladders by seat and stack]]
[[IMAGE: icm_postflop_geometry | SPR control and risk management under ICM]]

Why it matters
When money jumps loom, chips lost hurt more than chips won help. That shifts good chips-EV calls into folds, especially when covered. Clear preflop shove/reshove trees reduce tough postflop spots. Postflop, prefer pot control OOP and choose pressure only when blockers and coverage favor you.

Rules of thumb
- Stack roles: big stacks apply pressure; medium stacks avoid thin calls and flats OOP; short stacks pick clean shove/call-off trees rather than speculative calls.
- Preflop ladders: map shove/reshove to 3bet_ip_9bb and 3bet_oop_12bb proxies; keep 4bet_ip_21bb and 4bet_oop_24bb value-lean. Bluff 4-bets are rare under ICM.
- Coverage logic: tighten call-offs when covered; widen slightly when you cover. Late-position steals widen for big stacks; calling ranges tighten.
- Postflop: small_cbet_33 on dry when uncapped and safe. half_pot_50 only when it sets a clean commit line with value+equity. Avoid big_bet_75 without clear size_up_wet equity and narrative.
- Line selection: protect_check_range more OOP to avoid stack-off. delay_turn and probe_turns only when the turn meaningfully shifts ranges and risk is acceptable.
- Exploits: mediums overfold turns when covered - tag overfold_exploit and press. Avoid hero-calls without blockers; fold is fine under ICM.
- Geometry: plan flop+turn to avoid all-in confrontations when covered. Prefer fold over thin peels that create dominated rivers.

Mini example
Bubble, 9-max. CO 35bb opens 2.2bb and is covered by BTN 60bb and blinds. BTN responds with 3bet_ip_9bb (reshove-proxy). CO folds KJo that would be a chips-EV defend, because covered and risk premium is high. If CO had AQo, choose 4bet_ip_21bb only when BTN is loose and there is a shorter stack elsewhere; otherwise fold. Postflop is mostly avoided by using clean preflop trees.

Common mistakes
- Calling off because it is barely chips-EV while covered. Under ICM, that is a punt; fold and keep ladder equity.
- Flatting OOP with medium stack to "see a flop." You invite bad SPR and tough call-offs; prefer 3bet_oop_12bb shove-proxy or fold.
- Vanity turn barrels when covered. Use half_pot_50 only with value+equity; otherwise protect_check_range and realize.
- Bluff 4-betting tight players. Under ICM, keep 4bet_ip_21bb and 4bet_oop_24bb value-lean.
- Triple-barreling scare cards without blockers or coverage advantage. Your story must fit.

Mini-glossary
Risk premium: extra equity required to continue because busting costs payout equity.
Covered: opponent has you out-chipped; your bust risk is higher.
3bet_ip_9bb / 3bet_oop_12bb: shove/reshove family proxies to simplify trees under ICM.
4bet_ip_21bb / 4bet_oop_24bb: value-lean 4-bet families; bluffing rare.
small_cbet_33 / half_pot_50 / big_bet_75: size families; choose smaller and safer under ICM pressure.
protect_check_range / delay_turn / probe_turns: lines to control risk or time aggression.
overfold_exploit: node where population folds too much under pressure.

Contrast
Versus chips-EV deep-stack play, ICM shifts value from thin calls and bluffs toward folds and jam-first trees. You win by avoiding dominated commitments when covered and by applying disciplined, blocker-backed pressure when you cover.
