# Poker Analyzer Agent Instructions

## Scope
These instructions apply to the entire repository.

## Code
- Keep diffs small (ideally touching 1–2 files).
- Treat enums as append-only; avoid reordering or renaming existing entries.
- Maintain a single canonical guard site for `SpotKind`.

## Testing
Run the following commands before submitting changes:

```bash
dart format --set-exit-if-changed .
dart analyze
dart test -r expanded test/guard_single_site_test.dart
dart test -r expanded test/mvs_player_smoke_test.dart test/spotkind_integrity_smoke_test.dart
flutter test
dart run tool/validate_training_content.dart --ci
```

If a command cannot run due to missing dependencies, note the issue in the PR description.
