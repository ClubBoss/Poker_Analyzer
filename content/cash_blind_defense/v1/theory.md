What it is
Blind defense is your plan from SB and BB versus opens from EP, MP, CO, and BTN, with BvB exceptions. You choose between call, 3-bet, or fold based on price, rake, and equity realization. BB gets the best pot odds but the worst position; SB pays more rake and realizes less, so it prefers 3-bet-or-fold versus early seats.

[[IMAGE: blind_defense_price_map | BB pot odds vs opens 2.2-2.5bb]]
[[IMAGE: blind_defense_3bet_ladders | SB/BB 3-bet/4-bet size ladders]]
[[IMAGE: blind_defense_postflop_matrix | OOP defense: boards to check-raise vs defend]]

Why it matters
Blinds face constant pressure. Calling badly out of position creates awkward SPRs and expensive turn and river guesses. Sound blind defense prints in micro, low, and mid pools because opens are frequent and folds compound. Correct sizes and tight postflop discipline prevent small leaks from snowballing.

Rules of thumb
- BB defense: call more versus CO/BTN due to price; 3-bet linear versus steals with high cards and blockers; 3-bet more polar versus EP/MP. Default size 3bet_oop_11bb; in BvB use 3bet_oop_10bb versus SB 2.5-3.0.
- SB defense: prefer 3-bet-or-fold versus EP/MP; allow selective flats versus CO/BTN when playability is high and rake does not punish. Keep 3bet_oop_11bb as baseline; standard 4-bet is 4bet_small_22bb.
- Squeeze plans: use squeeze_iso_3bet value-biased over open plus caller(s); avoid_bloated_pot_oop with weak offsuit broadways and dominated gappers. Position and rake punish thin flats.
- Postflop as caller OOP: protect_check_range often. Versus small_cbet_33 on dry Axx/Kxx, defend_vs_small_cbet with pairs, gutters plus overcards, and backdoor flush draws; mix check_raise_dry at some frequency where you have coverage. On T98/QJT, check_raise_wet only with strong equity; otherwise call or give_up_low_equity.
- Turn and river: know MDF but prioritize realization and geometry. deny_equity_turn with check-raise or bet only when you add real equity. Overfold versus half_pot_50 and big_bet_75 when ranges are tight and you are capped. probe_turns selectively after flop checks through on scare cards. polarize_river sparingly; call_down_top_pair mainly when ranges are capped and sizings are small.

Mini example
UTG opens 2.3bb, MP folds, CO folds, BTN folds. SB 3-bets to 11bb, BB folds, UTG calls.  
Flop A72r: SB small_cbet_33; UTG calls.  
Turn 5x: SB half_pot_50 to deny_equity_turn versus wheel gutters and overcards; UTG folds.  
Contrast branch: CO opens 2.3bb, BTN folds, SB folds, BB calls; flop T98ss, CO big_bet_75, BB continues only with pair plus draw or strong OESD and avoid_bloated_pot_oop raises.

Common mistakes
- Over-folding BB versus 2.2-2.5 opens. Why it is a mistake: price is good and position improves realization versus late seats; Why it happens: fear of tough turns leads to folding too many suited and connected hands.
- Over-calling SB. Why it is a mistake: rake and realization kill thin flats; Why it happens: copying BTN defense without accounting for position and fees.
- Flatting dominated offsuit broadways OOP. Why it is a mistake: poor realization and kicker traps; Why it happens: overvaluing card quality and ignoring position.

Mini-glossary
defend_vs_small_cbet: Continue versus ~33 percent bets with pairs, gutters plus overs, or BDFDs.  
protect_check_range: Structured checks that keep medium hands and avoid face-up lines.  
squeeze_iso_3bet: Value-biased 3-bet over open plus caller(s) using blockers and playability.  
deny_equity_turn / polarize_river: Bet or raise to fold live equity on turns; use large river sizes with value and bluffs when ranges cap.

Contrast
Blind defense is not BTN defense: OOP realization and rake make flats worse and 3-bet selection tighter. It also differs from BvB, where 3bet_oop_10bb is common and both ranges are wider.
