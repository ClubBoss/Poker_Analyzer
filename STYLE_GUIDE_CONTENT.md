# Poker Analyzer - Content Style Guide

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
  1) What it is - 2-3 lines
  2) Why it matters - 2-3 lines
  3) Rules of thumb - 3-5 bullets, each with a short "why"
  4) Mini example - 3-5 lines; must be rules-legal; use POSITIONS (UTG, MP, CO, BTN, SB, BB), not seat numbers
  5) Common mistakes - 3 bullets; each explains why it is a mistake AND why players make it
  6) Mini-glossary - include if new terms appear; if EV or angle shooting appear in text, include explicit "EV:" and "Angle shooting:" lines
  7) Contrast line - Core modules only; one sentence contrasting with adjacent module

DEMOS.JSONL
- 2-3 demo items.
- Each item: "id", "title", "steps"[], optional "hints"[] if schema allows.
- Each step is <= 1 line of text.

DRILLS.JSONL
- 12-16 drills.
- Each item: "id", "spotKind", "params"{...}, "target"[], "rationale".
- "rationale" is <= 1 line.
- Target labels must be snake_case tokens, not sentences, only [a-z0-9_].
- Must include these tokens for core_rules_and_setup coverage: no_reopen, reopen, bettor_shows_first, first_active_left_of_btn_shows, min_raise_legal, min_raise_illegal, string_bet_call_only, binding, returned.

RULES AND FORMULAS
- Min-raise rule: new_total - current_bet >= last_raise_size.
- Showdown defaults:
  - If there was a river bet and call: bettor_shows_first, then caller.
  - If no river bet: first_active_left_of_btn_shows.
- Opensize guidance: write "typical online open size is 2-3bb at 100bb", not a universal rule.

SPOTKIND DISCIPLINE
- Use ONLY SpotKind values from the allowlist provided in the prompt for the target module.
- Do NOT invent new kinds in content. If a new kind is needed, first propose a Codex PR to add enum + actions/subtitle maps, then use it in content.

QUALITY GATES
- Content must pass: tooling/content_audit.dart and test/content_audit_smoke_test.dart.
- No new dependencies, no schema changes via content files.
