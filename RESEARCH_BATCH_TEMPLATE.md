# Research Batch Template — Content Phase

## Input
```
GO MODULES: <id1>,<id2>,<id3>
STYLE OVERRIDE: (as in PROMPT_RULES.md)
```

## Output
For each `<id>` produce exactly 3 files:
```
content/<id>/v1/theory.md
content/<id>/v1/demos.jsonl
content/<id>/v1/drills.jsonl
```

### theory.md
- 450–550 words max.
- Short blocks, mobile-friendly.
- Sections:
  1. What it is
  2. Why it matters
  3. Rules of thumb (bullets)
  4. Mini example
  5. Common mistakes

### demos.jsonl
- 2–3 entries.
- Walk-through style, step-by-step in <= 1 line per step.
- ID format: `<moduleId>:demo:NN`.

### drills.jsonl
- 12–16 entries.
- Varied parameters.
- Rationale <= 1 line.
- ID format: `<moduleId>:drill:NN`.
- SpotKind must match enum in lib/ui/session_player/models.dart.

## Constraints
- ASCII only.
- Must pass `dart test test/content_schema_test.dart`.
