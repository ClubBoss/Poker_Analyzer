Content Pipeline Make Targets

Usage
- Run the image pipeline (generate specs, render stub SVGs, insert links):
  - `make images`
- Generate the GAP report and JSON (prints table + TOP GAPS footer, writes build/gaps.json):
  - `make gap`
- Full beta (images then gap):
  - `make beta`
- Optional local zip of content/ after beta:
  - `make beta-zip`

Module‑Scoped Examples
- Generate specs for a single module:
  - `dart run tooling/gen_image_specs.dart core_board_textures`
- Render stubs for a single module:
  - `dart run tooling/render_images_stub.dart --module core_board_textures`
- Link images in theory.md for a single module:
  - `dart run tooling/link_images_in_theory.dart --module core_board_textures`

Notes
- Deterministic ordering; allowlists are optional and handled gracefully.
- Recipes avoid global formatting to work around unrelated parse errors.
- All commands are ASCII‑only and have no new dependencies.

Fix terminology
- Auto-fix across Markdown and JSONL, then confirm clean:
  - `make fix-terms`
- Full pass with fixes + images + artifacts:
  - `make beta-fix`
- Module-scoped preview (no writes):
  - `dart run tooling/term_lint.dart --module <id> --fix-dry-run --fix-scope=md+jsonl`

Continue mode
- Run the full fix + images + reports pipeline without stopping on failures:
  - `make beta-fix-continue`
- Useful for exploratory runs to still produce whatever artifacts are possible.
- Quick artifact peek:
  - `ls -l build/`
  - `head -n 80 build/gaps.json`
  - `head -n 80 build/term_lint.json`
  - `unzip -l build/beta_content.zip`
