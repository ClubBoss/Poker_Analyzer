# Project Status — Poker Analyzer

## Phase
**CONTENT**  
Skeleton phase is complete. All curriculum loaders and status scaffolding are in place.  
We now fill each module with content (theory, demos, drills).

## Active Docs
- [CONTENT_SCHEMAS.md] — source of truth for file formats and validation
- [RESEARCH_BATCH_TEMPLATE.md] — generation contract for Research chat
- [PROMPT_RULES.md] — prompt discipline for Codex and Research

## Process
- Use `bin/next_content_batch.dart` → `tool/send_research_prompt.sh` to get `GO MODULES: …`.
- Paste into Research with STYLE OVERRIDE (cheat-sheet format).
- Save generated files under `content/<id>/v1/`.
- Run `dart test test/content_schema_test.dart` to validate.

## Notes
- Theory: 450–550 words max, short blocks, bullets, examples, common mistakes.
- Demos: 2–3 concise walk-throughs.
- Drills: 12–16 varied, one-line rationales.
- Goal = maximize EV: less reading, more doing.
