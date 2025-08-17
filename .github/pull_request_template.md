<!-- Title: short, imperative, scoped (e.g., feat(l3): ..., fix(ui): ..., ci: ...) -->

## Summary
- what/why
- scope
- rollback

## Quality Footer (must pass)
- [ ] enum append-only: SpotKind changed only by appending last + trailing comma, no renames/reorders
- [ ] single guard occurrence: exactly 1 occurrence of .contains(spot.kind) (canonical guard path only)
- [ ] format/analyze clean: `dart format --set-exit-if-changed .` and `dart analyze` are clean
- [ ] actions/subtitle match task: new/changed kinds have correct actions and subtitle mapping
- [ ] no new deps/strings unless required (i18n later)
- [ ] tiny, reversible diff: 1-2 files, minimal surface, rollback plan noted
- [ ] tests (if touched): pass locally; Flutter-free where possible

Canonical guard (keep centralized):

```
!correct && autoWhy && (spot.kind == SpotKind.l3_flop_jam_vs_raise || spot.kind == SpotKind.l3_turn_jam_vs_raise || spot.kind == SpotKind.l3_river_jam_vs_raise) && !_replayed.contains(spot)
```
