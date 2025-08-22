# Content PR

## Module
- [ ] Module ID: <!-- e.g., core_rules_and_setup -->

## Checklist
- [ ] `dart format . && dart analyze` run clean locally.
- [ ] No non-ASCII punctuation (smart quotes / long dashes) in content files.
- [ ] Exactly three files added/updated:
  - [ ] content/<module_id>/v1/theory.md
  - [ ] content/<module_id>/v1/demos.jsonl
  - [ ] content/<module_id>/v1/drills.jsonl
- [ ] ASCII-only. No smart quotes or long dashes.
- [ ] theory.md is 450–550 words with required sections; Core has a contrast line.
- [ ] demos.jsonl has 2–3 items; each step one line.
- [ ] drills.jsonl has 12–16 items; targets are snake_case tokens, not sentences.
- [ ] Edge cases covered for core_rules_and_setup:
  - [ ] short all-in reopen logic
  - [ ] river bettor_shows_first
  - [ ] no-bet first_active_left_of_btn_shows
  - [ ] out-of-turn and string bet
- [ ] SpotKind values are from SSOT. No new kinds invented.
- [ ] `dart run tooling/content_audit.dart <module_id>` passes locally.

## Notes
- Keep diffs minimal. No new dependencies.
