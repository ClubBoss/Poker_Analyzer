What it is
This module explains pot_odds, equity, and outs, and how to turn them into fast decisions. Pot_odds tell you the price of a call: call / (pot + call). Equity is your chance to win at showdown. Outs are cards that improve you to the best hand. The rule_of_2_and_4 helps estimate equity from outs in seconds.

Why it matters
You face calls and raises constantly. Converting prices into breakeven_equity makes decisions objective instead of guesswork. When you know your equity and compare it to the price, you can choose call_vs_raise or fold without emotion and protect long-run EV.

Rules of thumb
- Compute pot_odds: call / (pot + call); breakeven_equity equals pot_odds; compare to your equity to decide why a call gains or loses.
- Count clean_outs only; discount tainted outs that pair the board, make an opponent a better hand, or complete your weak draw, because true equity falls.
- Rule_of_2_and_4: on the flop multiply outs by 4 to approximate turn+river equity; on the turn multiply by 2 for river equity; quick and close for 8-14 outs, less accurate at extremes.
- Direct_odds vs implied_odds: if future betting is unlikely, use direct_odds; if you can win extra when you hit, implied_odds can justify a call; beware reverse_implied_odds when a made hand can still be second best.
- Multiway: equity is diluted when more players see the next card; tighten calls unless implied_odds are strong.

Mini example
BTN bets 30 into a 120 pot on the turn. Your call is 30. Pot after calling would be 150. pot_odds = 30 / (120 + 30) = 0.20. If you estimate equity at 22 percent, calling is profitable versus the price. Sanity check: EV(call) = equity * (pot + call) - (1 - equity) * call. At equity = breakeven_equity = 0.20, EV(call) = 0.20 * 150 - 0.80 * 30 = 30 - 24 = +6 (near 0 for small call relative to pot, rounding aside).

Common mistakes
- Counting all outs as clean_outs; mistake because some outs are counterfeit_outs or give villains better hands; players do it because counting is easier than judging tainted cards.
- Ignoring reverse_implied_odds; mistake because you pay more on later streets when dominated; players see a price now and forget future losses.
- Overtrusting rule_of_2_and_4 at extremes; mistake because 2 and 4 overstate equity with many blockers or few outs; players rely on speed instead of checking context.

Mini-glossary
- Pot_odds: the price of a call, call / (pot + call); equals breakeven_equity.
- Equity: chance to win the pot at showdown, expressed as a fraction.
- Outs: cards that make your hand best; use clean_outs, not all visible cards.
- Rule_of_2_and_4: quick equity estimate from outs (x4 on flop, x2 on turn).
- EV: expected value per decision, the average profit or loss over many trials.

Contrast line
This module converts prices and chances into decisions; the adjacent module "core_positions_and_initiative" focuses on where you act and who drives the action, not on math.