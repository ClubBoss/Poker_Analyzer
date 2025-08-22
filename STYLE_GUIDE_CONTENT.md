# Poker Analyzer — Content Style Guide

GOALS
- Produce consistent, mobile-first training content that passes automated audits.
- Keep language simple. Define every new term in a Mini-glossary.

GLOBAL RULES
- ASCII-only. Straight quotes. Use "-" not en/em dashes. No hyperlinks or tables.
- Paths: content/<module_id>/v1/...
- IDs: "<module_id>:demo:NN" and "<module_id>:drill:NN". NN is zero-padded 2-digit.
- JSONL: one JSON object per line. No trailing commas. Valid UTF-8 ASCII subset.

THEORY.MD
- 450-550 words total.
- Required sections:
  1) What it is — 2-3 lines
  2) Why it matters — 2-3 lines
  3) Rules of thumb — 3-5 bullets, each with a short "why"
  4) Mini example — 3-5 lines; must be rules-legal
  5) Common mistakes — 3 bullets; each explains why it is a mistake AND why players make it
  6) Mini-glossary — include only if new terms appear (2-4 entries, one line each)
  7) Contrast line — Core modules only; one sentence contrasting with adjacent module
- Legality constraints for Mini example:
  - Action order correct; folded players never act later.
  - Pot size increases monotonically when bets occur; hand ends logically.
  - Showdown consistency with river action.

DEMOS.JSONL
- 2-3 demo items.
- Each item: "id", "title", "steps"[], optional "hints"[] if schema allows.
- Each step is <= 1 line of text.

DRILLS.JSONL
- 12-16 drills.
- Each item: "id", "spotKind", "params"{...}, "target"[], "rationale".
- "rationale" is <= 1 line.
- Target labels must be snake_case tokens, not sentences, only [a-z0-9_]. Keep them concise.
- Include mandatory edge-case drills for the "core_rules_and_setup" module:
  - Short all-in (< min-raise) and whether it reopens betting.
  - River show order with a river bet (bettor_shows_first).
  - River show order with no river bet (first_active_left_of_btn_shows).
  - Out-of-turn and string bet identification.

RULES AND FORMULAS
- Min-raise rule: new_total - current_bet >= last_raise_size.
- Showdown defaults:
  - If there was a river bet and call: bettor_shows_first, then caller.
  - If no river bet: first_active_left_of_btn_shows first.
- Opensize guidance: write "typical online open size is 2-3bb at 100bb", not a universal rule.

SPOTKIND DISCIPLINE
- Use ONLY SpotKind values from the SSOT list.
- Do NOT invent new kinds in content. If a new kind is needed, first propose a Codex PR to add enum + actions/subtitle maps, then use it in content.

QUALITY GATES
- Content must pass: tooling/content_audit.dart and test/content_audit_smoke_test.dart.
- No new dependencies, no schema changes via content files.
