What it is
An ICM mid-ladder decision playbook for non-HU finals and near-finals. You reuse fixed actions and families only: preflop ladders 3bet_ip_9bb, 3bet_oop_12bb, 4bet_ip_21bb, 4bet_oop_24bb; postflop families size_down_dry and size_up_wet; sizes small_cbet_33, half_pot_50, big_bet_75. Every decision resolves to one token such as protect_check_range, delay_turn, probe_turns, double_barrel_good, triple_barrel_scare, call, fold, or overfold_exploit. No new sizes or trees.

Why it matters
ICM nonlinearity means chips lost hurt more than equal chips won. Staying inside 33/50/75 keeps plans simple while you protect checks, delay at mid SPR versus raise-prone players, and upgrade only with blockers and evidence.

Rules of thumb
- Family by texture. Static (A83r, K72r) -> size_down_dry; dynamic (JT9ss, 986ss) -> size_up_wet. Why: board physics first reduces guesswork.
- Default sizes. Dry -> small_cbet_33; wet -> half_pot_50. Why: baseline denial and control with lower variance under ICM.
- 12-20bb band. Favor delay_turn and protect_check_range OOP; avoid thin upgrades. Why: shallow stacks amplify bust risk.
- 20-35bb band. Use half_pot_50 on dynamic turns; upgrade to big_bet_75 only with blockers + Fv75 up. Why: raises remain costly.
- 35bb+ band. Pressure increases IP, but river discipline tightens; thin calls require blockers + data. Why: deeper stacks still face ICM risk against polar lines.
- Upgrade + commitment gates. Move to big_bet_75 only with blockers and documented Fv75 up, and pass the commitment check (a 75% turn must not force bad rivers); otherwise keep half_pot_50 or delay_turn. Why: bigger needs proof and a plan.
- Delay vs raise-prone. Choose delay_turn with medium strength when raise risk is high. Why: preserve equity and avoid ICM disasters.
- Probe rule. Sequence: chk-chk -> probe_turns on favorable turns only. Why: initiative comes from the skip.
- Protect early OOP. Use protect_check_range on stabby textures. Why: deny auto-profit stabs and maintain realization.
- River discipline. Population under-bluffs polar big_bet_75; without blockers -> fold; with scare + top blockers and a plan -> call or triple_barrel_scare as PFA. Why: blockers filter bluffs.
- Preflop ladders. Value-weight 4bet_ip_21bb or 4bet_oop_24bb in low 5-bet rooms; gate overfold_exploit with repetition. Why: avoid spew vs traps.
- Multiway caution. Favor half_pot_50 and thin value via size_down_dry; reduce pure bluffs. Why: equity splits and ICM pressure compound.
- Table speed / fatigue. Simplify to small_cbet_33, half_pot_50, delay_turn, protect_check_range; avoid fancy upgrades without evidence. Why: accuracy beats thin edges under ICM.

Mini example
- CO vs BTN IP on T98ss: size_up_wet -> half_pot_50; turn scare with nut blocker and Fv75 up -> big_bet_75 for double_barrel_good; river on second scare with plan -> call or triple_barrel_scare depending on blockers.
- BB OOP on K72r static: size_down_dry -> small_cbet_33 at controlled frequency; raise-prone IP at mid SPR -> delay_turn; river facing polar 75% without blockers -> fold.
- Preflop value ladder: MP opens, CO 3-bets thin, BTN folds, blinds tight; you hold value IP -> 4bet_ip_21bb in a low 5-bet room.

Common mistakes
- Upgrading to big_bet_75 without blockers or Fv75 evidence.
- Probing turns without the chk-chk sequence.
- Hero-calling polar 75% rivers without blockers.
- Mixing families (e.g., size_up_wet label with small_cbet_33 plan by default).
- Off-tree sizes from fear or excitement.
- Tagging overfold_exploit after one orbit of folds.

Mini-glossary
Fv50/Fv75: observed fold rates versus 50% and 75% bets; justify upgrades and calls.
Blocker gates: specific blockers that remove key continues and unlock big_bet_75 or river calls.
Raise risk: likelihood villain raises your bet; higher risk pushes toward delay_turn and protection.
Commitment gate: turn check that a 75% barrel will not force a bad river without equity/blockers.
Stack band: coarse depth category (12-20, 20-35, 35+ bb) that biases token choices, not sizes.

Contrast
Compared to cash and HU ICM, mid-ladder ICM tightens upgrade and call gates, favors delay_turn and protect_check_range OOP, and keeps the same tokens and the 33/50/75 family.

[[IMAGE: icm_midladder_pressure_map | Stack bands -> token levers]]
[[IMAGE: icm_turn_upgrade_gates | 50 -> 75% gates under ICM]]
[[IMAGE: icm_river_discipline | Polar 75%: blockers/discipline]]
