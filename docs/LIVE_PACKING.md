Live Content Packing

Purpose: build JSON artifacts for Live modules without Flutter. Useful for preview and delivery.

Outputs
- Per-module: `build/live/<moduleId>/v1/module.json`
- Index: `build/live/index.json` with counts per module

Validation
- Uses the JSONL validator/loader, so malformed content fails fast.
- ASCII-only. Idempotent over existing files.

Examples
```
dart run tool/pack_live_content.dart
dart run tool/pack_live_content.dart --modules=live_etiquette_and_procedures --pretty
```

Artifacts
- `module.json`: `{ "moduleId": "<id>", "version": "v1", "theory": "...", "demos": [...], "drills": [...] }`
- `index.json`: `[ { "moduleId": "<id>", "version": "v1", "demos": N, "drills": M }, ... ]`

Notes
- `PACK OK <id> -> build/live/<id>/v1/module.json` on success.
- `PACK FAIL <id>: <reason>` on failure. Exit code 1 if any fail.
- `--modules` limits to a comma-separated subset. `--pretty` pretty-prints JSON.

