What it is
This module organizes play by ante phase in 9-max MTTs: pre-ante (no antes), early-ante (reduced), and full-ante (standard). Antes add dead money and lower everyone's required defense thresholds. Early seats exist in 9-max, so UTG and MP stay tighter for longer, while CO, BTN, and SB expand most as antes rise.

[[IMAGE: mtt_antes_pot_build | Pot size with antes vs no antes]]
[[IMAGE: mtt_open_defend_shifts | Opens and defends by phase (9-max)]]
[[IMAGE: mtt_postflop_flows | Small-cbet vs delay/probe by phase]]

Why it matters
Antes change risk-reward and geometry. Pots start larger, steals print more, and folding gives up more equity. SPR falls faster after 3-bets, so initiative and position gain value. Pools under-4bet and overfold turns; a phase-aware plan converts those leaks into chips.

Rules of thumb
- Preflop by phase: pre-ante keep UTG and MP disciplined and reduce OOP flats; early-ante widen CO/BTN steals; full-ante add SB steals and defend BB wider vs small opens. Why: dead money improves price and realization for late seats.
- Size families: use 3bet_ip_9bb vs late steals; 3bet_oop_12bb from blinds; keep 4bet_ip_21bb value-heavy vs tight 3-bettors and mix 4bet_oop_24bb sparingly. Why: these sizes preserve leverage and clean SPR across phases.
- Multiway control: with more players behind in 9-max, prefer 3bet_oop_12bb over loose flats OOP; add squeezes in prose only, but map to our size families. Why: dominated multiway spots create bad SPRs on turns and rivers.
- Flop and turn defaults: small_cbet_33 on dry Axx/Kxx; half_pot_50 when ranges are closer; big_bet_75 only with size_up_wet and real equity. OOP on middling textures, use protect_check_range. Why: texture-fit sizing prints and avoids spew.
- Turn and river levers: delay_turn and probe_turns gain power as antes rise; tag overfold_exploit where pools fold too much. Choose double_barrel_good on range cards and triple_barrel_scare on credible river scares. Why: you shift pressure to the streets opponents misplay most.

Mini example
Pre-ante: UTG opens 2.2bb, MP folds, CO folds, BTN calls, SB folds, BB calls. Flop A72r: UTG small_cbet_33; BTN folds, BB calls. Turn 4x: UTG half_pot_50 as double_barrel_good with Ax; check more with KQ.
Full-ante: CO opens 2.3bb, BTN 3bet_ip_9bb, SB folds, BB folds, CO calls. Flop J96r: CO protect_check_range; turn Qx improves BTN who fires half_pot_50; river A enables triple_barrel_scare when blockers align.

Common mistakes
- Copying pre-ante frequencies into full-ante. Why it is a mistake: opens too tight and steals missed. Why it happens: anchoring to earlier phases.
- Flatting too much OOP in early seats. Why it is a mistake: you invite dominated multiway spots; 3bet_oop_12bb performs better. Why it happens: fear of building pots preflop.
- Auto big_bet_75 without equity on dynamic turns. Why it is a mistake: you get raised or torch EV; half_pot_50 or delay_turn fits better. Why it happens: size inertia.

Mini-glossary
Pre-ante / early-ante / full-ante: phases defined by antes that change ranges and prices.
overfold_exploit: intentional pressure where pools fold too much, often on turns.
protect_check_range: OOP checks that keep medium hands and avoid face-up lines.
delay_turn / probe_turns: bet the turn after prior street checks (IP/OOP).
small_cbet_33 / half_pot_50 / big_bet_75: core size families mapped to texture.
3bet_ip_9bb / 3bet_oop_12bb / 4bet_ip_21bb / 4bet_oop_24bb: preflop size families to keep leverage and SPR in line.

Contrast
Compared with 6-max cash, 9-max antes add early seats and more callers behind. You steal more by phase, control multiway with 3bet_oop_12bb, and lean on delay_turn and probe_turns to exploit turn overfolds while keeping 4bet_ip_21bb value-lean.

_This module uses the fixed families and sizes: size_down_dry, size_up_wet; small_cbet_33, half_pot_50, big_bet_75._
