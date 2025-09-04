Developer Fast Lane

Use the Live fast lane to run a minimal, deterministic subset of checks without Flutter.

Examples:

- Run all with fail-fast (default):

```
dart run tool/fast_live_check.dart --fail-fast
```

- Run tests only (skip format and analyze):

```
dart run tool/fast_live_check.dart --no-format --no-analyze
```

- Run lint only (skip tests):

```
dart run tool/fast_live_check.dart --no-test
```

Flags:

- `--fail-fast` (default true)
- `--no-format`
- `--no-analyze`
- `--no-test`

Output is ASCII-only and terse, e.g.:

```
FORMAT: PASS
ANALYZE: PASS
TESTS: PASS
```

Normalize content IDs (optional helper):

```
# Dry-run for two modules only
dart run tool/normalize_content_ids.dart --modules=math_intro_basics,hu_exploit_adv

# Apply changes (still validates before/after)
dart run tool/normalize_content_ids.dart --modules=math_intro_basics,hu_exploit_adv --write
```
