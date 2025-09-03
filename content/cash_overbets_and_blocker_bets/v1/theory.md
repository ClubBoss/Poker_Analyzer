What it is
Overbets are large polar bets on turns or rivers used when your range holds nut advantage or strong blockers. Blocker bets are small, thin-value or set-price bets on static nodes where both ranges are condensed. In practice we map these ideas to size families: big_bet_75 as the polar lever, size_down_dry as the blocker/thin-value lever, and half_pot_50 as the default when neither extreme fits. small_cbet_33 remains a flop baseline on dry boards.

[[IMAGE: overbet_nut_advantage_map | Boards and positions that enable overbets]]
[[IMAGE: blocker_bet_spots | Thin value / set-price nodes]]
[[IMAGE: river_tree_overbet_blocker | Polar vs merge trees and sizes]]

Why it matters
Sizing drives fold equity, value capture, and future geometry. Polar pressure punishes capped ranges and missed draws; small blocker bets harvest thin value and control exposure versus raise-happy opponents. Pools often overfold to big polar bets out of position and under-raise rivers versus small bets. Disciplined deployment prints while staying solver-aligned.

Rules of thumb
- Use big_bet_75 when you have nut advantage or strong blockers and villain is capped. Classic nodes: paired middles, high-card turns that favor the aggressor, and rivers where front-door draws miss while your range carries top-end density. Why: polarization maximizes EV by extracting with nuts and folding out bluff-catchers.
- Prefer size_down_dry on static rivers with condensed ranges when you hold thin value. You set a price, target bluff-catchers, and deter large raises. Why: small bets protect equity realization and still get called by worse pairs and ace-highs.
- Half_pot_50 is the default turn/river size when range interaction is balanced or unclear. It retains fold equity, keeps rivers playable, and avoids committing with marginal hands. Why: medium sizing maintains flexibility across runouts.
- After small_cbet_33 on dry flops, fire double_barrel_good on range-shifting turns; if the river brings a credible scare that your line supports and blockers confirm, use triple_barrel_scare. Why: geometry plus narrative raises fold rates at the right time.
- Out of position on middling textures without nut share, protect_check_range. Do not force thin bets that expose you to raises. Why: OOP realization is poor; avoid donating to polar raises with capped holdings.
- Defense versus polar sizing: call when you block value and unblock bluffs; fold more when your blockers are poor and your range is capped. Raise rarely unless you hold clear nuts.

Mini example
UTG folds, MP opens 2.3bb, CO folds, BTN calls, SB folds, BB calls. Flop Q72r. MP makes a small_cbet_33; BTN calls, BB folds. Turn 4x checks through. River 7 pairs; front-door draws miss. BTN holds A7s (trips; good blocker to boats). Versus capped MP, BTN chooses big_bet_75 to polarize for value and bluff with Ac5c in mixes. If BTN instead held QJ with no boat blockers, BTN prefers size_down_dry to target worse queens and pocket pairs while capping exposure versus raises.

Common mistakes
- Treating big_bet_75 as a bluff-only tool. Why it is a mistake: you need strong value plus blocker bluffs to avoid under-bluff/over-bluff extremes. Why it happens: confusion between polar and pure-bluff strategies.
- Using size_down_dry on volatile textures or short-SPR turns. Why it is a mistake: small bets get raised or give free cards. Why it happens: copying flop habits without texture checks.
- Auto half pot on every river. Why it is a mistake: you miss EV by ignoring nut advantage and blocker stories. Why it happens: comfort with a single size.
- Calling polar bets with weak blockers. Why it is a mistake: population overbets are often under-bluffed; fold more without good blockers. Why it happens: curiosity calls.

Mini-glossary
big_bet_75: Large polar bet for value and bluffs when you hold advantage.
size_down_dry: Small blocker/thin-value sizing on static nodes.
half_pot_50: Default pressure when neither polar nor blocker fits well.
small_cbet_33: Cheap flop bet on dry boards to deny and keep worse hands in.
double_barrel_good: Second barrel on turns that improve your range.
triple_barrel_scare: Final barrel on credible scare rivers.
protect_check_range: Checking to keep medium hands and avoid exploitation.

Contrast
Unlike baseline small_cbet_33 trees that realize equity cheaply, this module shifts to polarized big_bet_75 and size_down_dry on later streets to maximize fold equity or thin value while keeping defense sound against opponents' polar sizing.
