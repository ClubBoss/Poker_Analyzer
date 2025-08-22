# Prompt Rules — Poker Analyzer

## Core Principles
- Tiny reversible diffs (Codex).  
- One source of truth for modules:
- Research phase: RESEARCH_QUEUE.md
- Codex/skeleton: tooling/curriculum_ids.dart
- Content only generated via Research chat.  

## Research Prompts
- Always start with:  
  `GO MODULE: <id>`  
  `STYLE OVERRIDE: …`  

- Style override **must** include:  
  - Audience: beginner-friendly, mobile-first.  
  - Theory.md = 450–550 words, with explicit sections:
    1. What it is  
    2. Why it matters  
    3. Rules of thumb (with *why* each rule matters)  
    4. Mini example (step explained)  
    5. Common mistakes (with explanation why they happen)  
  - Demos.jsonl: 2–3 items, step ≤ 1 line.  
  - Drills.jsonl: 12–16 items, rationale ≤ 1 line.  
  - ASCII-only (7-bit). No long dashes, no smart quotes.  
  - JSONL strictly valid, unique IDs.  

## Zip Prompts
- Must always return ZIP with correct structure: `content/<module>/v1/...`  
- Must append universal pipeline:

```bash
ZIPFILE=$(ls -t batch*.zip | head -n1)
rm -rf content
unzip -o "$ZIPFILE" -d .
dart format .
dart analyze
dart test test/content_audit_smoke_test.dart
dart run tooling/content_audit.dart
dart test
git add .
git commit -m "Add content batch"
git push
```

## Guard Clause
Keep canonical auto-replay guard unchanged:
```
!correct && autoWhy &&
(spot.kind == SpotKind.l3_flop_jam_vs_raise ||
 spot.kind == SpotKind.l3_turn_jam_vs_raise ||
 spot.kind == SpotKind.l3_river_jam_vs_raise)
 && !_replayed.contains(spot)
```
