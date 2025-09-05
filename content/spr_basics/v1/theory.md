What it is
SPR (stack-to-pot ratio) is the stack remaining behind relative to the pot at the start of a street. It shapes value thresholds, bluff viability, and pressure plans, while sizes remain fixed. Preflop ladders control SPR: 3bet_ip_9bb and 3bet_oop_12bb lower SPR; 4bet_ip_21bb and 4bet_oop_24bb create cleaner, lower SPRs. Texture still picks the size family: size_down_dry on static boards and size_up_wet on dynamic boards. SPR then nudges frequencies inside those families, not the sizes themselves.

Why it matters
Low SPR favors commit-capable value and simpler lines; trim thin calls and use small_cbet_33 or half_pot_50 to realize equity. High SPR allows more maneuvering: thinner value on static with size_down_dry and more delayed lines when raises are likely. You keep trees and sizes constant and adjust only how often you use each token.

Rules of thumb

* 3bet_oop_12bb / 3bet_ip_9bb reduce SPR and lift the value of top pairs and initiative. Why: bigger pot vs stack improves realization for the aggressor.
* 4bet_ip_21bb / 4bet_oop_24bb set clean SPR; trim OOP flats near low SPR. Why: simpler commitment math and fewer tough nodes.
* Low SPR + static flop -> size_down_dry with small_cbet_33. Why: cheap denial and easy turn decisions.
* Higher SPR + dynamic flop -> size_up_wet; start half_pot_50, upgrade to big_bet_75 with blockers. Why: leverage vs draws while controlling variance.
* Commit thresholds: if a turn big_bet_75 leaves trivial behind on the river, plan double_barrel_good only with equity and blockers. Why: clean realization at low SPR.
* Low SPR does not auto-call: fold vs big_bet_75 without blockers in under-bluffed pools. Why: population effect dominates price.
* Mid-SPR OOP vs raise-prone IP -> delay_turn with medium strength and protect_check_range. Why: avoid getting blown off equity.
* High SPR after chk-chk -> probe_turns more. Why: opponents surrender turns at high SPR after missing the flop stab.
* Keep ladders and sizes fixed; SPR shifts frequencies only. Why: consistency under pressure.

[[IMAGE: spr_definition_tiles | SPR definition with street start examples]]
[[IMAGE: spr_by_ladder | How 9/12/21/24 preflop sizes set SPR]]
[[IMAGE: spr_texture_matrix | Texture family (dry/wet) × low/medium/high SPR play]]

Mini example
HU 100bb 3-bet pot (low SPR): BB 3bet_oop_12bb vs SB 2.0bb. Flop JT9ss (dynamic) -> half_pot_50; turn Qs with blockers -> double_barrel_good, consider big_bet_75 (size_up_wet) if folds spike.
HU SRP (high SPR) on A83r: IP small_cbet_33 for thin value (size_down_dry); facing raise-happy IP when OOP, choose delay_turn on K72r-3x.
River discipline: mid/low SPR scare river facing big_bet_75 without blockers -> fold.

Common mistakes

* Equating low SPR with auto-stacking regardless of pool under-bluffs.
* Forcing off-tree sizes to engineer shoves; only 33/50/75 are allowed.
* Over-bluffing high SPR rivers on static runouts.
* Calling too many medium-equity hands OOP at mid SPR.
* Skipping protect_check_range vs stabby IP and getting probed off equity.

Mini-glossary
SPR: stack-to-pot ratio at street start.
Clean SPR: low, simple SPR created by 4-bets for clear decisions.
Commitment threshold: point where remaining stack makes future shoves trivial.
Realization: how well your hand converts equity to EV given position/SPR.
Leverage: pressure created by bet size relative to remaining stack.

Contrast
rake_and_ante_economics changes incentives via fees and dead money; donk_bets_and_leads covers OOP initiative vs PFA. SPR is the geometry that shapes frequency choices using the same tokens and families.
