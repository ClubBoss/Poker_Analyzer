Derived Allowlists

Purpose
- Speed up content validation by generating per-module allowlists from existing demos/drills.
- Makes `content_gap_report.dart` and `term_lint.dart` flag only truly invalid tokens.

What It Derives
- `tooling/allowlists/spotkind_allowlist_<module>.txt` from `spot_kind|spotKind` in `demos.jsonl` and `drills.jsonl`.
- `tooling/allowlists/target_tokens_allowlist_<module>.txt` from `target|targets` in `drills.jsonl`.

Rules
- Deterministic: one token per line, sorted ascending, ASCII-only.
- Sentinel: with `--clear`, writes a single line `none` when a derived set would be empty.

CLI Usage
- Preview (default dry-run, shows diff):
  - `dart run tooling/derive_allowlists.dart`
- Write files:
  - `dart run tooling/derive_allowlists.dart --write`
- Single module:
  - `dart run tooling/derive_allowlists.dart --module core_board_textures --write`
- Clear empty (write `none`):
  - `dart run tooling/derive_allowlists.dart --write --clear`
- Quiet mode:
  - `dart run tooling/derive_allowlists.dart --quiet --write`

Output
- One-liner summary:
  - `ALLOWLISTS modules=<N> wrote=<K> skipped=<M> empty=<E>`
- Per-module concise lines unless `--quiet`.

Notes
- Does not modify content files.
- Does not touch SSOT/guards; generates only under `tooling/allowlists/`.
