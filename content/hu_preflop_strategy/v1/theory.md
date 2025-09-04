What it is
This module gives a clear, solver-aligned plan for Heads-Up preflop. Positions are SB (Button, in position) and BB (out of position). You will use compact open sizes when deep, add SB limp mixes when shallow, and follow stable ladders for 3-bets and 4-bets: 3bet_oop_12bb, 3bet_ip_9bb, 4bet_ip_21bb, 4bet_oop_24bb.

[[IMAGE: hu_ranges_grid | Default SB and BB HU preflop ranges by depth]]

Why it matters
In HU, every hand is a blind battle, so small preflop edges repeat hundreds of times. Clean sizes and simple frequency rules reduce noise, protect EV, and set up easier postflop play. A fixed ladder also improves execution speed and reduces leaks under pressure.

[[IMAGE: hu_size_ladders | Size ladders: opens, 3-bets, 4-bets by depth]]

Rules of thumb
- SB open size: 2.0bb at 60100bb, 2.22.5bb at 2540bb, add SB limp mixes at 1525bb; why: smaller risk deep, more pressure mid, lower variance shallow.
- BB 3-bet size: 3bet_oop_12bb versus 2.02.5bb opens; why: puts SB in a bind without over-committing and maps cleanly to 4bet_ip_21bb.
- SB vs BB iso over limp: use 3bet_ip_9bb as a jam proxy at 1525bb with suited Ax, pairs, and high-card suiteds; why: fold equity plus robust equity when called.
- 4-bet ladders: use 4bet_ip_21bb versus 12bb 3-bets, and 4bet_oop_24bb when BB 4-bets versus an IP 3-bet line; why: consistent risk-to-reward and stack mapping.
- Calling ranges tighten as stacks shrink; why: less room to realize equity and higher penalty for dominated offsuit hands.
- Rake-free or ante formats: open slightly wider and defend more; why: cheaper pots and more dead money make marginal hands viable.

[[IMAGE: hu_depth_matrix | Depth matrix: open, limp, 3-bet, and call mixes]]

Mini example
UTG, MP, CO not seated. BTN is SB. BB posts 1bb. 100bb effective.  
SB opens 2.0bb with a standard range. BB 3-bets to 12bb.  
With A5s, SB prefers 4bet_ip_21bb as a blocker-driven bluff. With KQs, SB calls.  
With AKo, SB 4-bets for value. If BB faces a 21bb 4-bet with AQs, BB can call at 100bb but folds more often at 60bb due to worse implied odds.

Common mistakes
- Oversizing SB opens deep. You risk more to win blinds and invite larger 3-bets; players do it to chase folds now instead of earning EV later.
- Flatting too wide from BB. Many offsuit hands bleed chips OOP; players hate folding two cards and overestimate realization.
- Never limping shallow. At 1525bb, a limp mix boosts EV with middling hands; players avoid it because they fear passivity and prefer uniform opens.
- 4-betting too small. Sizes below 4bet_ip_21bb or 4bet_oop_24bb give great price; players copy full-ring sizes that do not map to HU stacks.
- Ignoring rake or antes. Wrong assumptions skew ranges; players assume all sites play the same preflop economics.

Mini-glossary
Open: the first raise from SB when action reaches you. Sets the initial price.  
Iso-raise: BB raises over an SB limp, usually to 45bb shallow.  
Blocker: a card that removes combos of strong continues, improving bluff success.  
Ladder: a fixed size mapping for 3-bets and 4-bets that stays stable across spots.  
Jam proxy: a smaller raise that captures most of a jams fold equity without committing full stack.

Contrast
This module sets HU preflop sizes and ranges; later HU postflop modules focus on c-bet frequencies and turn/river plans.
