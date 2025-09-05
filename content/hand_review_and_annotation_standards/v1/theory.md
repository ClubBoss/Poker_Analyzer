What it is
This module defines how to review hands and write minimal annotations that translate directly into one action token. You will log texture, price, position, initiative, blockers, raise risk, sequence, pressure gates, and SPR. Then you will map to exactly one of: 3bet_ip_9bb, 3bet_oop_12bb, 4bet_ip_21bb, 4bet_oop_24bb, small_cbet_33, half_pot_50, big_bet_75, size_up_wet, size_down_dry, protect_check_range, delay_turn, probe_turns, double_barrel_good, triple_barrel_scare, call, fold, overfold_exploit. Trees and sizes never change; postflop families are 33/50/75 only.

Why it matters
Consistent notes compress a hand into repeatable cues. Physics first: texture picks size family (size_down_dry on static like A83r/K72r; size_up_wet on dynamic like JT9ss/986ss). Reads and economics shift only frequencies. Tokenized annotations make drills, solver checks, and in-game execution align.

Rules of thumb

* Annotation grammar: one line per street with Price (pot/size), Texture (dry/wet), Family (33/50/75), Position (IP/OOP), Initiative (PFA/Caller), Blockers, Raise risk, Sequence (chk-chk/x/r threat), Pressure gate (Fv50/Fv75 trend), SPR band (low/mid/high), Token.
* Mandatory tags: Texture, Family, Initiative, Position, Blockers, Sequence, Pressure gate, SPR band. If one is unknown, mark “n/a” and be conservative.
* Conversion rule: every street annotation ends in exactly one token. No mixed strategies in notes.
* Texture discipline: never change sizes; record family as size_down_dry on static, size_up_wet on dynamic. Token = small_cbet_33 / half_pot_50 / big_bet_75 inside that family.
* Triage priorities: price errors first; wrong family second; missed probe_turns after check-check; turn double barrels without blockers; river calls without blockers in polar nodes.
* Preflop ladders: record ladder use only (3bet_ip_9bb / 3bet_oop_12bb / 4bet_ip_21bb / 4bet_oop_24bb). Overfold tags require persistence before overfold_exploit.
* Raise-risk handling: if “raise-prone IP” at mid SPR, prefer delay_turn or protect_check_range; log the choice.
* Probe vs lead: Sequence “chk-chk” flags probe_turns; do not mislabel as a lead.
* Commitment planning: if turn big_bet_75 would leave trivial behind, annotate the commit gate; require equity/blockers or stay at half_pot_50.
* Drill pipeline: each reviewed hand yields one demo (steps) and one drill (Q -> single token). Keep wording identical to tokens.

[[IMAGE: annotation_schema_tiles | Minimal hand annotation schema]]
[[IMAGE: tag_to_token_map | From annotations -> tokenized actions]]
[[IMAGE: review_to_drills_flow | Hand -> standardized note -> spaced drill]]

Mini example
Preflop: HU 100bb. SB 2.0bb open; Note “PF: Fv3B up, 4B down (medium)”. BB blockers A5s. Token -> 3bet_oop_12bb (overfold_exploit only after persistence).
Flop: 3-bet pot K72r. Texture=dry, Family=33, PFA=OOP, SPR=low-mid, Raise risk=normal. Token -> size_down_dry + small_cbet_33.
Turn: K72r-5x. Sequence=called, Raise risk=high vs this villain, SPR=mid. Token -> delay_turn.
River: K72r-5x-2x. Facing polar big_bet_75, Blockers=poor. Token -> fold.

Common mistakes

* Verbose paragraphs with no token. Fix: one line per street, one token.
* Off-tree sizes to “explain” a feeling. Fix: 33/50/75 only; record family then token.
* Ignoring blockers at river. Fix: require blocker note before call or triple_barrel_scare.
* Missing Sequence tag, so probes are never taken. Fix: mark chk-chk; add probe_turns.
* Mixing EV rants with reads. Fix: store only cues that map to tokens.
* Tagging overfold_exploit on one hand. Fix: require repetition tiers.

Mini-glossary
Annotation grammar: the one-line structure per street with required tags and a token.
Texture tag: dry/wet label that selects size family.
Family: 33/50/75 sizing group used by the token.
Sequence tag: action flow (chk-chk, x/r risk) that unlocks probe_turns or protection.
Pressure gate: fold-vs-size read (Fv50/Fv75) that guides half_pot_50 vs big_bet_75.
Blockers: cards that block value or unblock bluffs; must be logged before thin calls or polar barrels.
SPR band: low/mid/high leverage context at street start.
Token set: the fixed actions allowed in review and play.

Contrast
study_review_handlab describes the weekly workflow; online_notes_* covers live tagging. This module standardizes how every reviewed hand is written so it maps cleanly to the same tokens without adding sizes or trees.
