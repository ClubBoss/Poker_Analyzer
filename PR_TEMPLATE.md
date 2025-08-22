# Content PR

## Module
- [ ] Module ID: <!-- e.g., core_rules_and_setup -->

## Checklist
- [ ] `dart format . && dart analyze` run clean locally.
- [ ] No non-ASCII punctuation (smart quotes / long dashes / bullets) in content files.
- [ ] Exactly three files added/updated:
  - [ ] content/<module_id>/v1/theory.md
  - [ ] content/<module_id>/v1/demos.jsonl
  - [ ] content/<module_id>/v1/drills.jsonl
- [ ] theory.md is 450-550 words with required sections; Core has a contrast line.
- [ ] Mini example uses positions, not seat numbers.
- [ ] demos.jsonl has 2-3 items; each step one line.
- [ ] drills.jsonl has 12-16 items; targets are snake_case tokens, not sentences.
- [ ] Edge cases covered for core_rules_and_setup:
  - [ ] short all-in reopen logic (no_reopen / reopen)
  - [ ] river bettor_shows_first
  - [ ] no-bet first_active_left_of_btn_shows
  - [ ] min_raise_legal and min_raise_illegal
  - [ ] out-of-turn and string bet (binding / returned / string_bet_call_only)
- [ ] SpotKind values are from the prompt allowlist for this module. No new kinds invented.
- [ ] `dart run tooling/content_audit.dart <module_id>` passes locally.
