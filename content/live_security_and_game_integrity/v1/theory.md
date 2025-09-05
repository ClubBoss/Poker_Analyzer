What it is
A defensive playbook for spotting live integrity risks (soft-play clusters, chip-dump patterns, marked/defective deck suspicions, device/communication cues, angle pressure, repeated dealer/procedural errors) and translating them into frequency shifts using our fixed tokens only. Sizes/trees never change. Preflop ladders: 3bet_ip_9bb, 3bet_oop_12bb, 4bet_ip_21bb, 4bet_oop_24bb. Postflop families: small_cbet_33, half_pot_50, big_bet_75. Concepts: size_up_wet, size_down_dry, protect_check_range, delay_turn, probe_turns, double_barrel_good, triple_barrel_scare, call, fold, overfold_exploit. Physics first: static (A83r/K72r) → size_down_dry; dynamic (JT9ss/986ss) → size_up_wet. Integrity context only nudges frequencies.

Why it matters
Compromised games erase edges and raise cognitive load. Sticking to 33/50/75 and 9/12/21/24 while choosing safer tokens (protection, delay, disciplined river folds, evidence-gated exploits) preserves EV, reduces tilt, and buys time to document and escalate to the floor without leaking.

Rules of thumb
- Soft-play suspected (two players avoid confronting each other): tighten aggression; add protect_check_range and trim double_barrel_good bluffs; vs polar rivers without blockers, fold to big_bet_75. Why: reduce exposure when ranges aren’t honest.
- Chip-dump vibe / strange all-in asymmetry: prefer merged value (half_pot_50), fewer thin calls; default fold vs big_bet_75 without blockers. Why: protect against engineered volatility.
- Marked/defective deck suspicion (handling/repeats): simplify lines—small_cbet_33 on static, half_pot_50 on dynamic; avoid fancy bluffs. Why: execution certainty while you document and call floor between hands.
- Angle pressure (string-bet traps, out-of-turn induces): earlier protect_check_range; at mid SPR choose delay_turn. Why: avoid getting blown off equity.
- Repeated heads-up against a “protected” seat (others overfold): with persistent evidence, tag overfold_exploit preflop (widen 3bet_ip_9bb / 3bet_oop_12bb); keep postflop discipline. Why: price edge without changing sizes.
- River fear nodes amplified in compromised games: default fold to big_bet_75 without blockers; as PFA on scare with blockers, triple_barrel_scare only if plan was set prior. Why: population under-bluffs.
- Chaotic multi-limp/deal quality issues: favor merged (half_pot_50), thin value via size_down_dry, fewer pure bluffs. Why: realization drops multiway.
- Surveillance/enforcement strict (string_bet, single_motion_raise_legal enforced): raise frequency falls—use delay_turn and protect_check_range more. Why: fewer random raises.
- Enforcement loose/chaotic: protect earlier (protect_check_range), default half_pot_50, keep families tight. Why: control variance amid unpredictability.
- Show-order clarity (bettor_shows_first / first_active_left_of_btn_shows): harvest info; after flop chk-chk, plan probe_turns. Why: sequence-driven initiative.
- Device/communication cues near action (report ethically): keep baseline conservative; prefer small_cbet_33 / half_pot_50; avoid thin hero calls. Why: reduce exploitability while floor assesses.
- If disputes repeat around same cluster: document hands; keep conservative tokens; never invent sizes. Why: discipline while gathering evidence.

Overlay flags (defensive, frequency only)
integrity_flags: softplay_suspected, chip_dumping_suspected, marked_deck_suspected, angle_risk_high, dealer_error_repeat, enforcement_strict, enforcement_loose.
Validators you may note for context: string_bet, single_motion_raise_legal, bettor_shows_first, first_active_left_of_btn_shows.

[[IMAGE: integrity_signal_matrix | Common integrity signals -> tokenized responses]]
[[IMAGE: angle_defense_flow | Angle pressure -> protect/delay/discipline chooser]]
[[IMAGE: overlay_to_family | Overlay flags -> family stays 33/50/75; frequencies shift]]

Mini example
1) Soft-play suspicion: BvB SRP on K72r (static) checks through. Log softplay_suspected. Turn: choose probe_turns (sequence); river facing big_bet_75 without blockers → fold. Sizes unchanged (33/50/75).
2) Angle pressure, strict room: 3BP turn on dynamic card; raise-prone opponent, enforcement_strict. Pick delay_turn instead of thin barrel; separate session note shows persistent fast folds to your 12bb—next orbit you widen with 3bet_oop_12bb under overfold_exploit (evidence-gated).

Common mistakes
- Paranoia → off-tree bets. Fix: keep 33/50/75; shift frequency only.
- Calling polar rivers without blockers. Fix: default fold vs big_bet_75.
- Tagging overfold_exploit after one hand. Fix: require repetition.
- Mixing probes/leads. Fix: probe_turns only after chk-chk.
- Ignoring protection in loose enforcement rooms. Fix: add protect_check_range / delay_turn.
- Trying to “test” integrity with spewy lines. Fix: document and escalate; keep tokens conservative.

Mini-glossary
Soft-play: coordinated avoidance of confrontation.
Chip dumping: intentionally shifting chips via unnatural lines.
Angle: procedural pressure to induce mistakes.
Enforcement strict/loose: how tightly rules (e.g., string_bet) are applied.
Documentation mindset: timestamp, seats, sequence, token taken.
Evidence gate: repetition threshold before exploits.

Contrast
Unlike live_etiquette_and_procedures (broader conduct) and live_floor_calls_and_dispute_resolution (rulings), this module turns integrity risk into conservative frequency shifts with the same tokens, keeping physics-first family selection intact.
