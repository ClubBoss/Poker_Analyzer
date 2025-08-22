# Research Template — Single Module Mode (v3)

Authoritative template for generating **one module** per prompt.

---

## Prompt Structure

```
GO MODULE: <module_id>

STYLE OVERRIDE:
  - Audience: <target group>
  - Tone: <instruction style>
  - Rules:
    * Theory.md = 450–550 words with explicit sections:
      1) What it is (2–3 lines)
      2) Why it matters (2–3 lines)
      3) Rules of thumb (3–5 bullets) — each bullet adds a short "why"
      4) Mini example (3–5 lines)
      5) Common mistakes (3 bullets) — for each: why it is a mistake AND why players make it
      6) Mini‑glossary (only if new terms appear): 2–4 entries, one line each
      7) (Core only) Contrast line: one sentence "how this differs from the adjacent module"
    * Demos.jsonl = 2–3 items, step <= 1 line
    * Drills.jsonl = 12–16 items, rationale <= 1 line
    * Math modules: include one "sanity check" line verifying the formula in the mini example
    * HU/Live modules: include one "population exploit hook" line in drills
  - ASCII-only; plain quotes; use "-" not long dashes; "%" for percentages
  - JSONL strictly valid; unique IDs (<moduleId>:demo:NN, <moduleId>:drill:NN)

MODULE SPECIFICS:
  - Short, module-tailored bullets (5–7 lines max)
  - Emphasis (math depth, exploit vs GTO, live vs online)
  - Constraints (positions, stacks, bet sizes, board types)
  - Example guidance (hands, boards)
  - Pitfalls to spotlight

VICTORY CONDITIONS:
  - Theory.md includes all required sections (incl. mini‑glossary if new terms)
  - Demos.jsonl: 2–3 items, steps single‑line, valid JSONL with unique IDs
  - Drills.jsonl: 12–16 items, each with <= 1‑line rationale, valid JSONL with unique IDs
  - For Math: a clear sanity‑check line is present
  - For HU/Live: one explicit population‑exploit hook appears in drills
  - ASCII‑only, no smart quotes/dashes
  - Passes `dart run tooling/content_audit.dart` and `dart test test/content_audit_smoke_test.dart`

DELIVER:
  - content/<module_id>/v1/theory.md
  - content/<module_id>/v1/demos.jsonl
  - content/<module_id>/v1/drills.jsonl

CHECKS:
  - Must pass `dart run tooling/content_audit.dart`
  - Run `dart test test/content_audit_smoke_test.dart`
  - Deliver only if all checks are OK
```

### Notes
- One module → one prompt → one delivery set.
- No batching. Keep MODULE SPECIFICS concise and decisive.
