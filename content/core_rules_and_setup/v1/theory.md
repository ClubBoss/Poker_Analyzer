What it is
This module defines the table mechanics of Texas Hold'em. You will learn how blinds and the button rotate, who acts first on each street, and which actions are legal: check, bet, call, raise, fold. It also covers minimum raise math, short all-ins, showdown order, string bets, and out-of-turn handling.

Why it matters
Clear, shared procedures prevent arguments and angle shooting. When order of action and raise legality are automatic, you act faster and protect EV. Consistent rules also help you switch between live and online games without confusion.

Rules of thumb
- Rotation: BTN, SB, BB move one seat clockwise each hand; fairness comes from everyone posting equally over time.
- Who acts first: preflop begins left of BB; postflop begins left of BTN; this removes ambiguity and protects action.
- Min-raise math: new_total - current_bet >= last_raise_size; this keeps raise ladders consistent and prevents tiny click-backs.
- Short all-in: an all-in that is less than a legal raise does not reopen betting; this blocks forced re-raises by tiny stacks.
- Live vs online: a string bet is not a legal raise live; a single clear motion or prior verbal amount is required, while online clicks already define the amount.

Mini example
Blinds 1/2. UTG opens to 2.5bb (typical online). MP 3-bets to 4.0bb; last raise size was 1.5bb, and 4.0 - 2.5 = 1.5bb so it is legal. CO is short and goes all-in to 4.8bb; 4.8 - 4.0 = 0.8bb, which is below 1.5bb, so betting does not reopen. BTN, SB, BB fold in turn; no player who folded acts again. UTG calls 4.0bb and MP calls behind. Postflop, action starts left of BTN. Turn and river check through. With no river bet, the first active player left of BTN shows first at showdown.

Common mistakes
- Treating a multi-motion chip dump as a raise; mistake because without a prior verbal amount it is a call only. Players copy loose home-game habits.
- Assuming any all-in reopens action; mistake because only a legal raise size reopens. Players equate “more chips” with “raise.”
- Showing out of order; mistake because it gives free information. Players forget the bettor shows first after a river bet; otherwise first active left of BTN shows.

Mini-glossary
- EV: expected value, the long-run average you gain or lose from a decision.
- Angle shooting: using unclear actions to gain an unfair edge within technical rules.
- Last raise size: the size of the previous raise used to set the next minimum raise.
- String bet: multiple chip motions without a prior verbal amount; not a legal raise live.
- Showdown order: default who-tables-first rule based on whether there was a river bet.

Contrast line
This module teaches procedures and legality; the adjacent module “core_positions_and_initiative” focuses on how position and initiative create advantage, not on mechanics.