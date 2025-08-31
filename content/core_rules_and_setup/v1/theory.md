What it is
This module sets the core rules of Texas Hold'em: what the button and blinds do, action order on each street, what makes a bet or raise legal, who must show first at showdown, and how hands are ranked. We use UTG, MP, CO, BTN, SB, and BB so examples do not need seat numbers. You will see four exact markers throughout: first_active_left_of_btn, new_total - current_bet >= last_raise_size, bettor_shows_first, and first_active_left_of_btn_shows.

Why it matters
Shared rules prevent disputes and save time. When you know who acts next, which raises are legal, and who reveals first, you avoid penalties and focus on decisions. These mechanics are identical live and online, so good habits transfer across formats.

Rules of thumb
- Hand rankings, high to low: royal_flush, straight_flush, four_of_a_kind, full_house, flush, straight, three_of_a_kind, two_pair, one_pair, high_card; no suit priority. Ties: straight and straight_flush compare the top card; flush compares highest card, then kickers; full_house compares trips, then pair.
- Action order: preflop goes UTG -> MP -> CO -> BTN -> SB -> BB. Postflop, the first_active_left_of_btn acts first each street; BTN acts last among remaining players.
- Minimum raise math: a raise is legal only if new_total - current_bet >= last_raise_size. Example: if current_bet = 20 and last_raise_size = 20, then new_total must be at least 40 for a minimum raise.
- Short all-in: if an all-in increase is smaller than last_raise_size, betting does not reopen for players who already acted; they may only call or fold.
- Showdown order: if there was a river bet, bettor_shows_first. If the river checked through, first_active_left_of_btn_shows.

Mini example
6-max. Preflop: UTG folds, MP raises, CO folds, BTN calls, SB folds, BB calls. Flop: BB checks, MP bets, BTN calls, BB folds. Turn: MP checks, BTN bets, MP calls. River: both check. No river bet, so first_active_left_of_btn_shows: MP exposes first, then BTN. If BTN had bet river and MP called, then bettor_shows_first and BTN would reveal first. Note how order flips from preflop (left of BB) to postflop (left of BTN).

Common mistakes
- Ranking suits: awarding a pot to a supposed higher suit. Why wrong: Hold'em has no suit priority; identical five-card hands split. Why it happens: players import rules from other games.
- String bet: moving chips in multiple motions without a clear raise declaration. Why wrong: most rooms rule this a call, losing your intended raise. Why it happens: hesitation or unclear speech.
- Miscounting min-raises: comparing to the displayed total instead of last_raise_size. Why wrong: creates an illegal raise or a ruled call. Why it happens: players forget to test new_total - current_bet >= last_raise_size.

Mini-glossary
Button (BTN): dealer marker that sets postflop position and helps determine showdown order when checked.
Blinds (SB, BB): forced bets posted before cards are dealt; BB acts last preflop unless raised.
Street: a betting round (preflop, flop, turn, river).
last_raise_size: the most recent raise increment on the current street.
string bet: chips placed in more than one forward motion without a clear declared raise.

Contrast
This module covers procedure and hand ranking; the next module uses positions and initiative to guide who should attack first.