What it is
Live formats with straddles and bomb antes add dead money, rewire preflop position (UTG straddle), create limp-chains, and lower SPR. This module converts those quirks into frequency shifts using only our fixed ladders (3bet_ip_9bb, 3bet_oop_12bb, 4bet_ip_21bb, 4bet_oop_24bb) and size families (small_cbet_33, half_pot_50, big_bet_75). Physics first still rules: size_down_dry on static boards (A83r, K72r), size_up_wet on dynamic boards (JT9ss, 986ss). Etiquette/procedural differences do not change sizes; they change how often we apply each token.

Why it matters
Straddles and bomb antes inject dead money and tighten some early-position equities while encouraging more limps. Lower SPR makes commitment clearer and thin flats worse OOP. The biggest wins come from picking the correct family by texture, then shifting frequencies toward merged value, protection, disciplined river folds, and evidence-gated preflop pressure—without inventing new lines.

Rules of thumb

* Dead money present: selectively widen steals and 3-bets with blockers via 3bet_ip_9bb / 3bet_oop_12bb; tag overfold_exploit only after repeated folds. Why: better price but evidence needed.
* UTG straddle positional shift: EP plays tighter; upgrade premiums to 4bet_ip_21bb / 4bet_oop_24bb versus early opens. Why: value prints when 5-bets are rare.
* Limp-chains (multi_limpers): prefer merged lines; use half_pot_50 for value, thin value via size_down_dry; reduce pure bluffs; add protect_check_range. Why: multiway realization is low.
* Lower SPR from bigger preflop pots: on static flops choose small_cbet_33; on dynamic turns default half_pot_50, upgrade to big_bet_75 only with blockers + fold-to-75 evidence (size_up_wet). Why: leverage must be justified.
* chk-chk frequency rises: when SRP checks through, use probe_turns on favorable turns. Why: surrender after passivity is common.
* Raise-prone turns at mid SPR: choose delay_turn with medium strength, keep protect_check_range earlier. Why: avoid getting blown off equity.
* River discipline: live polar rivers are under-bluffed; fold vs big_bet_75 without blockers; as PFA on scare + blockers, consider triple_barrel_scare. Why: population tendency.
* Table_speed or fatigue up: bias to small_cbet_33, half_pot_50, protect_check_range, delay_turn; avoid fancy triple_barrel_scare. Why: accuracy under load.
* Economics interface: straddle/bomb ante shifts frequencies only; ladders 9/12/21/24 and 33/50/75 families remain fixed. Why: consistency.

Live overlay integration

* has_straddle: widen 3bet_ip_9bb / 3bet_oop_12bb with blockers; probe_turns more after chk-chk; preserve size families.
* bomb_ante: more dead money → merged value with half_pot_50; thin value via size_down_dry; protect_check_range in multiway.
* multi_limpers: shift toward protection and merged value; fewer pure bluffs.
* avg_stack_bb down: lower SPR → small_cbet_33 on static, default half_pot_50 on dynamic; upgrade to big_bet_75 only with blockers.
* table_speed down: simplify to small_cbet_33 / half_pot_50, delay_turn.
  Validator awareness (string-bet/one-motion) helps keep sizes inside 33/50/75 but does not change which family we choose.

[[IMAGE: straddle_positional_shift | UTG straddle → action order and pressure lanes]]
[[IMAGE: bomb_ante_dead_money_map | Where dead money boosts steals & merged value]]
[[IMAGE: multiway_family_picker | Multi-limpers: 33/50/75 family chooser]]

Mini example
Single straddle on. SB opens light; BB with A5s notes repeated blind folds → 3bet_oop_12bb (evidence-gated, overfold_exploit). Flop A83r heads-up: size_down_dry → small_cbet_33. Turn 6c, room raises turns aggressively → delay_turn. River faces big_bet_75 on a polar line without blockers → fold.
Bomb ante with limp-chain: you isolate, flop T92r multiway → half_pot_50 for merged value; turn checks through often in this pool → probe_turns on the 6x.

Common mistakes
Off-tree size improvisation; over-bluffing into limp-chains; forgetting UTG straddle positional tightening; confusing probe_turns (after chk-chk) with turn leads (after calling a c-bet); hero-calling polar big rivers without blockers; skipping protect_check_range in raise-happy rooms.

Mini-glossary
Straddle: live blind posted before cards, adds dead money and shifts position.
Bomb ante: large ante from all players each hand; increases dead money and lowers SPR.
Limp-chain: multiple limpers preflop, leading to multiway pots.
Reverse SPR: lower SPR created via larger preflop ladders (e.g., 4bet_*), clarifying commitment.
Capped node: range lacking top value; prime for probe_turns.
Merged vs polar: medium-strength value vs nuts/air; map to half_pot_50 vs big_bet_75 respectively.

Contrast
Live_tells_and_dynamics focuses on reads; live_etiquette_and_procedures on process. Here we center on format economics and positional rewiring from straddles/bomb antes. Sizes remain 33/50/75; only frequencies move.
