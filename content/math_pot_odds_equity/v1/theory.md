What it is
This module is a deep-dive on pot odds and equity for Heads-Up, also usable in 6-max. You will compute call price X/(P+X), bluff breakeven B/(P+B), quick equity from outs using the rule-of-2-and-4 with simple blocker notes, and equity realization by position. You will connect the numbers to actions using only: 3bet_ip_9bb, 3bet_oop_12bb, 4bet_ip_21bb, 4bet_oop_24bb, small_cbet_33, half_pot_50, big_bet_75, size_up_wet, size_down_dry, protect_check_range, delay_turn, probe_turns, double_barrel_good, triple_barrel_scare, call, fold, overfold_exploit.

[[IMAGE: pot_odds_chart | Pot odds and bluff breakeven at a glance]]

Why it matters
Math converts noisy spots into clear thresholds. When you know your equity and the price, you choose call or fold without guesswork. When you know required fold percentages, you select half_pot_50 or big_bet_75 and adjust with overfold_exploit where the pool folds too much.

[[IMAGE: equity_outs_grid | Quick equity from outs with blockers]]

Rules of thumb
- Call price: calling X into pot P needs equity >= X/(P+X). Example: calling 5bb into 10bb needs ~33%; calling 7.5bb into 10bb needs ~43%.
- Bluff breakeven: B into P needs folds = B/(P+B). half_pot_50 needs ~33% folds; big_bet_75 needs ~43% folds; smaller sizes need fewer folds but win less when called.
- Outs to equity: rule-of-2-and-4. Turn-to-river: ~2% per out; flop-to-river: ~4% per out. Discount dirty outs or when your hit pairs the board poorly.
- Position and realization: IP realizes more equity than OOP. Tighten near-threshold OOP calls; widen IP calls when implied odds exist, but account for reverse implied odds on dominated draws.
- Size families and ladders: size_down_dry with small_cbet_33 on static boards; size_up_wet with big_bet_75 on dynamic boards. Preflop defaults: 3bet_oop_12bb versus SB 2.0bb opens, 3bet_ip_9bb in position; 4-bet sizes are 4bet_ip_21bb and 4bet_oop_24bb. Blockers increase folds and reduce 4-bets.

[[IMAGE: realization_flow | Equity realization IP vs OOP and size selection]]

Mini example
Pot ~10bb on flop T84r. BB bets 5bb. SB holds Js9s with 8 clean outs. Turn-only equity ~16% and flop-to-river ~32%. Price needs ~33%. IP calls with implied odds; OOP folds more without them.  
As a bluff on 986ss turn with strong draw and blockers, big_bet_75 into 10bb needs ~43% folds, while half_pot_50 needs ~33%. Choose size_up_wet on dynamic turns and size_down_dry on static ones.  
Preflop at 100bb, SB opens 2.0bb. BB compares flat versus 3bet_oop_12bb with A5s. If the pool overfolds to 12bb, choose overfold_exploit by increasing 3-bet frequency with blockers. If SB 4-bets rarely, value 3-bet more; if SB 4-bets often, reduce bluff 3-bets and prefer playable calls IP.

Common mistakes
- Calling because the number is close while OOP. Error: poor realization turns break-even math into negative EV; why it happens: players treat raw equity as sufficient and ignore position and initiative.
- Oversizing bluffs on dry boards. Error: big_bet_75 needs ~43% folds that dry boards rarely deliver; why it happens: copying wet-board plans and chasing immediate folds.
- Ignoring dirty outs and blockers. Error: counting outs that make second best or bluffing without blockers; why it happens: focusing on hand strength instead of combo math and ranges.

Mini-glossary
Pot odds: the price to continue, X/(P+X), compared to your equity.  
Bluff breakeven: required folds, B/(P+B).  
Equity realization: how much of raw equity becomes EV after position and playability.  
Dirty outs: outs that also improve villain or create reverse implied odds.

Contrast
The math_intro_basics module surveys many tools; this module drills pot odds and equity deeper and ties them to size families and preflop ladders.
