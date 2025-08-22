# Research Template — Single Module Mode

This document defines the canonical template for generating **content files** for a single curriculum module.

---

## Prompt Structure

```
GO MODULE: <module_id>
STYLE OVERRIDE:
  - Audience: <target group>
  - Tone: <instruction style>
  - Rules:
    * Theory.md = 450–550 words
      1) What it is (2–3 lines)
      2) Why it matters (2–3 lines)
      3) Rules of thumb (3–5 bullets)
      4) Mini example (3–5 lines)
      5) Common mistakes (3 bullets)
    * Demos.jsonl = 2–3 items, step <= 1 line
    * Drills.jsonl = 12–16 items, rationale <= 1 line
DELIVER:
  - content/<module_id>/v1/theory.md
  - content/<module_id>/v1/demos.jsonl
  - content/<module_id>/v1/drills.jsonl
CHECKS:
  - ASCII only (7-bit)
  - Use "-" not "–/—"
  - Only "%" sign for percentages
  - Plain quotes (")
  - JSONL strictly valid, unique IDs
  - Run `dart run tooling/content_audit.dart` locally; only deliver if all checks = OK
```

---

## Notes
- One module -> one prompt -> one delivery set.
- Do not group modules into batches.
- Research must always tailor style to the module's audience and topic.
