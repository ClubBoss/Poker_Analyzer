## Quality Footer (must pass locally before submit)

- [ ] enum append-only: last == `l4_icm_sb_jam_vs_fold`, no dups/renames
- [ ] `dart format --set-exit-if-changed .` → no diffs
- [ ] `dart analyze` → 0 errors
- [ ] `_autoReplayKinds` used exactly once via `autoReplayKinds.contains(spot.kind)`
- [ ] `actionsMap` returns `['jam','fold']` for all kinds in `autoReplayKinds`
- [ ] `subtitlePrefix` contains non-empty exact prefixes for all kinds in `autoReplayKinds`
- [ ] New jam/fold kinds: updated **all three** of {`spot_specs.dart`: `autoReplayKinds`, `actionsMap`, `subtitlePrefix`}
- [ ] Tests: `dart test -r expanded test/mvs_player_smoke_test.dart test/spotkind_integrity_smoke_test.dart` pass

**Notes (optional):**
- Affected files:
- Risk (S/M/L):
- Rollback: revert this PR
