What it is
This module teaches fast combo counting and blocker logic for Heads-Up. You will count combos at a glance and turn removal effects into clear actions using only: 3bet_ip_9bb, 3bet_oop_12bb, 4bet_ip_21bb, 4bet_oop_24bb, small_cbet_33, half_pot_50, big_bet_75, size_up_wet, size_down_dry, protect_check_range, delay_turn, probe_turns, double_barrel_good, triple_barrel_scare, call, fold, overfold_exploit.

[[IMAGE: blockers_fast_grid | Quick combo blocks for pairs, suited, and offsuit]]

Why it matters
Blockers change the ratio of value to bluffs. Knowing what you remove improves bluff timing, tightens calls when you block bluffs, and expands thin value when you do not. Small edges compound and make lines harder to exploit.

[[IMAGE: removal_to_action | From removal counts to betting actions]]

Rules of thumb

* Quick combo math: pairs start at 6; one blocker cuts to 3, two to 1. Suited start 4; blocking suits -> 3/2/1. Offsuit start 12; block ranks -> 9/6; heavy board removal -> 3. Why: each removed card kills permutations.
* A/K/Q blockers vs 4-bets: an ace in BB reduces SB 4bet_ip_21bb (AA, AK); K/Q reduce KK/QQ/AK/AQ. Why: fewer value 4-bets improves 3bet_oop_12bb EV.
* Wheel-ace blockers: A5s is a premium 3-bet bluff because it blocks AA/AK and has equity when called. Why: removal plus playability.
* Flush/straight blockers: nut spade reduces bluff supply on spade rivers; T9 blocks straights on QJ8x. Why: fewer natural bluffs => fold more vs big_bet_75.
* Board-pair removal: on paired rivers, value combos collapse; thin value shifts to size_down_dry or check. Why: you block calls or split more often.
* Mapping to actions: size_up_wet with big_bet_75 when you do not block folds and you block calls; size_down_dry or delay_turn when you block calls; protect_check_range to avoid capped nodes; probe_turns when IP checks and turn favors you; double_barrel_good on improving turns; triple_barrel_scare with key blockers; overfold_exploit when pools fold too much.

[[IMAGE: river_scare_blockers | River scare cards and which blockers to bluff with]]

Mini example
UTG, MP, CO not seated. BTN is SB. BB posts 1bb. 100bb effective.
SB opens 2.0bb. You are BB with A5s. A blocks AA/AK, so 3bet_oop_12bb gains folds and reduces 4bet_ip_21bb frequency. Flop QJ8r, turn 2s checks through, river As. With AcTx you block AK/AQ value while unblocking KTs/T9 bluffs, so big_bet_75 is a strong bluff. With Qc9c you block KQ/QJ and some bluffs; prefer size_down_dry or check. On paired rivers like 772r-2x-5x, board removal slashes value sets, so thin value sizes down and many bluffs shut down.

Common mistakes

* Bluffing while blocking folds. Mistake: holding Qx on Q-high rivers blocks calls folding; EV drops. Why players do it: they overrate their own blockers to value, not to folds.
* Calling while blocking bluffs. Mistake: holding the nut spade on spade rivers removes bluffs; call rate should fall. Why players do it: they count raw strength, not bluff supply.
* Ignoring 4-bet removal. Mistake: 3-betting weak offsuit broadways without blockers into frequent 4-bettors. Why players do it: they chase action without combo math.

Mini-glossary
Removal: the reduction of opponent combinations caused by your cards or the board.
Dirty blocker: a card that removes both value and bluffs, making the net effect unclear.
Clean blocker: a card that mostly removes value or mostly removes bluffs so the direction is clear.
Pair removal: value shrinkage on paired boards that shifts you toward size_down_dry or check.

Contrast
Math_pot_odds_equity focuses on prices; this module focuses on how blockers and removal change value-to-bluff ratios and size choices.
