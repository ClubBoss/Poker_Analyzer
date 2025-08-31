[[IMAGE: positions_table | Positions at the table]]
[[IMAGE: hand_ranking_ladder | Hand ranking ladder]]
[[IMAGE: min_raise_math_chart | Min-raise math example]]

What it is
This module sets the core rules of Texas Hold'em: what the button and blinds do, who acts when on each street, what makes bets and raises legal, how showdown order works, and how final hands are ranked. We name positions UTG, MP, CO, BTN, SB, and BB so examples do not need seat numbers.

Why it matters
Shared procedure prevents disputes and penalties and keeps attention on decisions. When you know order, raise legality, and reveal rules, you act faster, avoid string-bet mistakes, and keep practice aligned with both live and online play.

Rules of thumb
- Hand rankings, highest to lowest: royal_flush, straight_flush, four_of_a_kind, full_house, flush, straight, three_of_a_kind, two_pair, one_pair, high_card. Why: this fixed ladder decides every showdown.
- Tie rules: no suit priority. Straights and straight_flush compare the top card; flush compares highest card, then kickers; full_house compares the trips, then the pair. Why: only card ranks break ties in Hold'em.
- Action order: preflop goes UTG -> MP -> CO -> BTN -> SB -> BB. Postflop the first actor is always the first_active_left_of_btn who has not folded. Why: the button sets postflop position.
- Minimum raise test: a raise is legal only if new_total - current_bet >= last_raise_size. Why: this preserves consistent raise increments.
- Short all-in: if an all-in increase is smaller than last_raise_size, betting does not reopen to players who already acted. Why: prevents tiny raises from forcing new action.
- Showdown order: if there was a river bet, bettor_shows_first; if the river checked through, first_active_left_of_btn_shows. Why: river aggression decides first reveal; otherwise position does.

Mini example
6-max. Preflop: UTG folds, MP raises, CO folds, BTN calls, SB folds, BB calls. Flop: the first_active_left_of_btn is BB, so BB acts first and checks; MP bets; BTN calls; BB folds. Turn: MP checks; BTN checks behind. River: BTN bets; MP calls. Because there was a river bet, bettor_shows_first, so BTN shows first. If river had checked through, first_active_left_of_btn_shows and BB would show first if still in.

Common mistakes
- Ranking suits. Mistake: claiming a spade flush beats a heart flush. Why it happens: imported home-game rules. Fix: no suit priority; compare ranks and kickers only.
- String bet in live play. Mistake: chips move forward in multiple motions without a clear raise declaration. Why it happens: hesitation or unclear speech. Fix: declare the total, then move chips in one motion.
- Miscounting min-raises. Mistake: comparing totals instead of the increment. Why it happens: skipping the difference test. Fix: use new_total - current_bet >= last_raise_size.

Mini-glossary
Button (BTN): dealer marker that sets postflop order and influences showdown when checked through.
Blinds (SB, BB): forced bets posted before cards that seed the pot; BB acts last preflop unless raised.
Street: a betting round (preflop, flop, turn, river).
last_raise_size: the most recent raise increment used in the min-raise test.

Contrast
This module covers procedure and hand comparisons; the next module uses positions and initiative to guide who should apply pressure first.