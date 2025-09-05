What it is
Final table playbooks are seat-by-seat guides for 9-max MTT endgames, where payout jumps create strong ICM pressure. Roles and coverage drive every choice: the chip leader (CL) applies pressure, medium stacks pay the highest risk premium, and shorts use clean shove/call-off trees.

[[IMAGE: ft_roles_pressure_map | Chip leader vs medium vs short roles by position]]
[[IMAGE: ft_3bet_4bet_ladders_icm | 3-bet/4-bet ladders under ICM & coverage]]
[[IMAGE: ft_postflop_risk_control | Postflop pressure vs control windows]]

Why it matters
At a final table, chips do not equal cash. Calling off too light when covered can torch multiple pay jumps. The CL can widen opens, 3-bets, and barrels because opponents fear busting. Seat-by-seat playbooks reduce guesswork: who to attack, who to avoid, and which sizes build fold equity without risking catastrophic all-ins.

Rules of thumb
- Roles and coverage: widen when you cover; tighten when covered. Shorts favor jam or fold trees mapped to 3bet_ip_9bb / 3bet_oop_12bb; mediums avoid dominated flats OOP; CL exploits position and blockers.
- Preflop ladders: use 3bet_ip_9bb vs CO/BTN steals and 3bet_oop_12bb from blinds; keep 4bet_ip_21bb and 4bet_oop_24bb value-lean. Bluff 4-bets are rare unless you cover and hold top blockers.
- Seat playbooks: EP/MP stay disciplined; CO/BTN/SB expand only when covering. Versus open+call, prefer squeeze (3bet_oop_12bb or 3bet_ip_9bb) when you cover; avoid cold-calling OOP.
- Postflop ICM: small_cbet_33 on safe static boards when uncapped. Use half_pot_50 to set clean two-street commit lines only with value+equity. Reserve big_bet_75 for size_up_wet or nut-advantage nodes as the cover. OOP, protect_check_range on middling.
- Tempo and exploits: as the cover, double_barrel_good on range turns; triple_barrel_scare only with blockers and a credible story. Tag overfold_exploit versus covered mediums who fold turns too often.
- Geometry: plan flop+turn to avoid marginal river call-offs when covered. Prefer fold over thin peels that create ugly rivers.

Mini example
9-handed. CO 40bb, BTN (CL) 65bb covers, blinds 25bb/30bb. CO opens 2.2bb. BTN 3bet_ip_9bb leveraging coverage. CO calls; pot ~20bb, stacks ~31bb, SPR ~1.6. Flop K72r: BTN small_cbet_33 to pressure underpairs and queen-highs while keeping the tree flexible. Turn Qx (range card for BTN): half_pot_50 as double_barrel_good, committing with Kx+ and strong draws. River bricks: BTN triple_barrel_scare only with blockers to two-pair/sets; otherwise check back. If roles were reversed (CO covers BTN), BTN should defend tighter and reduce turn barrel frequency.

Common mistakes
- Calling 3-bets or 4-bets too light when covered because “chip EV.” ICM makes those calls too expensive.
- Flatting OOP as a medium stack, inviting squeezes and bad SPRs.
- Using big_bet_75 without size_up_wet equity or nut share; you get check-raised and over-commit as the covered player.
- Bluff 4-betting without coverage or blockers; 4bet_ip_21bb / 4bet_oop_24bb should be value-lean.
- Ignoring overfold_exploit on turns versus capped mediums; leaving EV on the table as the cover.

Mini-glossary
Coverage: who can bust whom; being covered increases your risk premium.
Risk premium: extra equity needed to continue because busting is costly.
Commit line: pre-planned two-street sequence to all-in with value+equity.
Seat playbook: default actions by position under ICM and coverage.

Contrast
Compared to non-ICM middle stages, FT playbooks prioritize coverage-first pressure and fold equity over thin chip-EV calls. Versus PKO FTs, you ignore bounty overlay here; trees are tighter, 4-bets value-lean, and postflop aggression is gated by ICM rather than bounty incentives.

_This module uses the fixed families and sizes: size_down_dry, size_up_wet; small_cbet_33, half_pot_50, big_bet_75._
