What it is
Isolation raises target one or more limpers so you play heads up with the betting lead. You decide between iso, overlimp, or fold based on position, number of limpers, and limp-raise risk. Size ladders scale with limpers and position so you avoid multiway and land on clean SPRs for value capture and simple turn trees (typical online).

[[IMAGE: iso_sizing_ladder | IP/OOP iso size ladder]]
[[IMAGE: iso_spr_map | SPR after iso vs 1-3 limpers]]
[[IMAGE: iso_decision_tree | Isolate or overlimp cues]]

Why it matters
Limpers hide weak ranges and realize equity cheaply if you let the pot stay multiway. Correct iso sizes reclaim fold equity, isolate the weakest opponent, and build pots where top pair and c-bets perform well. Wrong sizes invite multiway, bloat OOP pots, and increase reverse implied risk, especially without position and kickers.

Rules of thumb
- IP sizing: vs 1 limper use iso_raise_ip_6bb (about 5-6bb). Add +1bb per extra limper. Size up in sticky pools or 120bb+; size down slightly at 40-60bb to preserve clean turn jam trees. Why: you want folds from bystanders and an SPR that rewards top pair.
- OOP sizing: from blinds vs 1 limper use iso_raise_oop_8bb (about 7-9bb). Add +1-2bb per extra limper. Keep ranges more value heavy and linear. Why: OOP realizes worse and needs leverage to avoid multiway.
- Range shapes: linear in soft fields (broadways, pairs, suited Ax/Kx), with blocker bluffs added more IP than OOP. Trim dominated offsuit broadways without kickers. Why: you want hands that flop top pair or strong draws and keep kicker advantage.
- Overlimp policy: overlimp_ok IP with suited connectors/gappers and small pairs when limp-raise risk is low and there are 2+ limpers. Rarely overlimp OOP. Why: these hands realize well and do not need to bloat the pot.
- Vs limp-raise: treat it as strong; fold_vs_limp_raise most mediums. Continue with clear value and occasional blocker 4-bet IP in deeper games. Why: population limp-raises are value heavy and reopen the betting.

Postflop after iso
IP favors small_cbet_33 on Axx/Kxx dry to tax floats; half_pot_50 on middling J-9 high boards; size_up_wet only with strong equity or robust backdoors. Use delay_cbet_ip when your hand benefits from turn cards or the board hits the limper. OOP protect_check_range, defend tighter vs raises, and pick clear value or give_up_low_equity. On turns, deny_equity_turn on scare cards that add overcards or complete draws. Rivers: polarize_river when ranges cap and draws miss; choose value_thin_ip after checks when your kicker advantage is clear.

Mini example
CO limps 1bb. BTN isolates to 6bb (iso_raise_ip_6bb). Blinds fold; CO calls. Pot ~13.5bb; stacks ~94bb; SPR ~7. Flop K72r. BTN small_cbet_33 ~4.5bb to tax broadways and gutshots; CO calls. Pot ~22.5bb; stacks ~89.5bb. Turn 5x adds wheel gutters; BTN half_pot_50 ~11.2bb to deny_equity_turn versus A5/86; CO folds. On QJ9ss instead, BTN often checks to protect_check_range and looks to delay_cbet_ip when a high turn improves range and blockers.

Common mistakes
- Using open sizes instead of iso sizes. Why it is a mistake: invites multiway and loses fold equity; Why it happens: copying raise habits without adjusting for limpers.
- Overlimping OOP with offsuit broadways. Why it is a mistake: poor realization and kicker traps; Why it happens: overvaluing card quality and underestimating position.
- Calling limp-raises too wide. Why it is a mistake: value heavy ranges crush mediums; Why it happens: fear of being exploited and ignoring blocker math.

Mini-glossary
iso_raise_ip_6bb: IP isolation raise vs 1 limper; add +1bb per extra limper.
iso_raise_oop_8bb: OOP iso vs 1 limper; add +1-2bb per extra limper.
overlimp_ok: Select overlimp when realization is high and limp-raise risk is low.
fold_vs_limp_raise: Tight response to limp-raise pressure; continue mainly with value.

Contrast
Unlike blind-vs-blind, iso pots target one capped limp-call range and aim to avoid multiway, so sizes push more folds and set heads-up SPRs that reward top pair and initiative.

_This module uses the fixed families and sizes: size_down_dry, size_up_wet; small_cbet_33, half_pot_50, big_bet_75._
