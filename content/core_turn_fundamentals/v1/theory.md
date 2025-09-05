content/core_turn_fundamentals/v1/theory.md
[[IMAGE: turn_equity_shift_examples | Turn equity shifts (e.g., A on K72, 3 on 964)]]
[[IMAGE: turn_sizing_tree | Turn sizing choices: small vs big]]
[[IMAGE: pot_geometry_spr_chart | Pot geometry and target SPR on river]]

What it is
This module covers turn play: when to fire a second barrel, how equity shifts change strategy, how blockers guide bluffing, and how pot geometry sets up the river. You will learn to choose sizes, plan two-street lines, and avoid automatic double-barrels.

Why it matters
The turn is the most expensive inflection point. Ranges narrow, bets get larger, and one error can cost stacks. Reading equity shifts and using blockers lets you win folds in tough spots, while smart pot geometry prepares clean river value bets or bluffs without awkward stacks.

Rules of thumb
- Barrel when the turn helps your range or hurts theirs. Overcards to middling boards often strengthen the preflop raiser, enabling pressure; undercards that connect the caller's range argue for caution.
- Size by purpose. Use bet_big_turn on dynamic cards that change best-hand ranks or add many draws; use bet_small_turn to deny equity and keep worse hands in when your value is thin.
- Prefer bluffs with blockers. Bluff more when you block top pairs, two-pair, or key draws and do not unblock folds; reduce bluffing when your hand unblocks their continuing range.
- Check_back more with medium-strength hands in position when reverse implied odds are high; delay_cbet turns that add equity or improve fold equity, especially after a flop check.
- Plan pot geometry. Choose a turn size so the river SPR fits your plan: set_up_river_jam for strong value or credible bluffs, or size_down_to_see_river with draws that realize well.

Mini example
UTG opens to 2.3 bb (typical online), BTN calls, blinds fold. Flop K72 rainbow; UTG cbet_small, BTN calls. Turn A two_tone. This card shifts equity toward UTG and gives Ax blockers that reduce Kx calls. UTG chooses bet_big_turn to pressure Kx and draws; BTN folds. Key points: identify the equity shift, pick size by purpose, and shape the river before you get there.

Common mistakes
- Auto-barreling any turn after a flop c-bet. Why it is a mistake: many bricks favor the caller and you burn equity. Why it happens: habit and fear of giving a free card.
- Using one turn size always. Why it is a mistake: value leaves chips on the table and bluffs lack fold equity. Why it happens: simplicity over structure.
- Ignoring pot geometry. Why it is a mistake: you arrive at the river with awkward stacks that cannot jam or credibly threaten. Why it happens: thinking in streets, not in plans.

Mini-glossary
Second barrel: A turn bet after betting the flop.
Equity shift: How board changes move range advantage from one player to the other.
Blocker: A card in your hand that reduces opponents' strong-hand combos, improving bluff success.
Pot geometry: Planning sizes across streets to target a desired river SPR and action.

Contrast
Unlike core_flop_fundamentals, which sets flop baselines, this module focuses on turn cards that change equities, selecting bluffs with blockers, and sizing to shape river outcomes.

_This module uses the fixed families and sizes: size_down_dry, size_up_wet; small_cbet_33, half_pot_50, big_bet_75._
