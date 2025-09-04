# Live Content Scaffold

Purpose: generate ASCII-only placeholders for the 11 live_* modules.

Run:

```
dart run tool/scaffold_live_content.dart
# or overwrite existing placeholders
dart run tool/scaffold_live_content.dart --force
```

Resulting tree example (one module):

```
content/live_tells_and_dynamics/
  v1/
    theory.md       # 6-8 line placeholder
    demos.jsonl     # first line comment + 1 JSON object
    drills.jsonl    # first line comment + 1 JSON object
```

Notes:
- Real content lands later via Research batches; placeholders are temporary.
- Tool is idempotent: by default creates files only if they are missing.
- Use --force to overwrite existing files when needed.

## ID Format
- Pattern: `^[a-z0-9_]+$` (ASCII lowercase letters, digits, underscore).
- Canonical shape: `<moduleId>_<demo|drill>_<NNN>` with zero-padded `NNN`.
- Examples: `live_etiquette_and_procedures_demo_001`, `cash_rake_and_stakes_drill_012`.
- Helpful tools: `tool/normalize_content_ids.dart`, `tool/fast_content_check.dart`.
