What it is
This module is a practical Heads-Up postflop playbook. It links flop, turn, and river into one plan for SB/Button (IP) versus BB (OOP). You will use sizing families small_cbet_33, half_pot_50, and big_bet_75, switch with size_down_dry or size_up_wet, and balance value with bluffs using protect_check_range, delay_turn, probe_turns, double_barrel_good, and triple_barrel_scare.

[[IMAGE: hu_size_families | Core sizing families and when to use each]]

Why it matters
HU ranges are wide and miss often, so size discipline controls EV and limits guesswork. A stable family of sizes improves execution under pressure, clarifies which hands mix checks, and shows when to exploit with overfold_exploit. The same patterns repeat across textures, so one compact system covers many boards.

[[IMAGE: hu_board_textures | Dry vs wet boards and pressure mapping]]

Rules of thumb
- size_down_dry on static boards like A83r or K72r. Prefer small_cbet_33 to fold air and keep range wide; why: these textures favor the preflop aggressor and do not need large bets to deny equity.
- size_up_wet on dynamic boards like JT9ss or 986ss. Prefer big_bet_75 with strong or high-equity hands; why: equity is volatile and draws need protection and fold equity.
- After small_cbet_33, choose double_barrel_good on turns that add equity or strain BBs range, and choose delay_turn on bricks with medium strength; why: press leverage when it rises, conserve when thin.
- In OOP lines after flop checks through, fire probe_turns on favorable cards; why: you gain fold equity, realize equity, and set up river decisions before IP can take control.
- Protect medium strength with protect_check_range. Mix checks that can continue versus a bet; why: your checking node stays hard to attack and prevents print-with-position spots.

[[IMAGE: hu_street_tree | Street-by-street decision tree with defaults]]

Mini example
UTG, MP, CO not seated. BTN is SB. BB posts 1bb. 100bb effective.  
Flop K72r, pot ~6bb. SB bets 2bb (small_cbet_33, size_down_dry). BB calls.  
Turn 3h, pot ~10bb. SB checks to delay_turn with Kx that fears a raise and targets lighter river calls.  
River Qc, pot ~10bb. BB bets 7.5bb (big_bet_75) as a polar stab. SB folds weak Kx that blocks few bluffs and unblocks value.

Common mistakes
- Over-betting dry boards. Mistake: big size folds out worse and isolates against strong hands; why players do it: they copy wet-board sizing and chase immediate folds.
- Auto-c-betting on wet textures. Mistake: small bets price in strong draws; why players do it: habit from dry boards and fear of giving a free card.
- Never protecting checks. Mistake: capped checks get punished by barrels; why players do it: fear of free cards with medium strength and discomfort playing turns out of position.

Mini-glossary
size_down_dry: choose smaller sizes on static boards where equities change little.  
size_up_wet: choose larger sizes on dynamic boards to protect equity and increase folds.  
protect_check_range: include some strong or bluff-catch hands in checks to avoid auto-muck nodes.  
probe_turns: OOP bet on the turn after flop checks through on a favorable card.

Contrast
HU preflop sets ranges and sizes; this module turns those ranges into street-by-street bets, checks, and folds using stable size families.
