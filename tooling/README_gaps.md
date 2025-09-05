Gaps TODO Planner

Purpose
- Compile a per-module TODO plan to quickly reach green content gates.
- Aggregates existing artifacts and lightweight content scans into a single checklist.

Inputs
- Artifacts (preferred; auto-generated if missing):
  - build/gaps.json (from content_gap_report.dart)
  - build/term_lint.json (from term_lint.dart)
  - build/links_report.json (from check_links.dart; optional)
- Repo scan:
  - content/*/v1/spec.yml to count images with status!=done or missing outputs.

CLI Usage
- All modules:
  - `dart run tooling/gaps_todo.dart`
- One module:
  - `dart run tooling/gaps_todo.dart --module core_board_textures`
- Quiet (only the one-liner):
  - `dart run tooling/gaps_todo.dart --quiet`
- Disable auto-generation of artifacts:
  - `dart run tooling/gaps_todo.dart --no-shell`

Output
- Writes `build/gaps_todo.md` with deterministic per-module sections:
  - `## <module_id>`
  - `- [ ] theory: missing_sections=<list|->, wordcount_out_of_range=<0|1>, images_missing=<0|1>`
  - `- [ ] demos: count_ok=<0|1>`
  - `- [ ] drills: count_ok=<0|1>, off_tree_sizes=<0|1>`
  - `- [ ] ids: duplicates=<0|1>`
  - `- [ ] allowlists: invalid_spot_kind=<0|1>, invalid_targets=<0|1>`
  - `- [ ] terminology: bad_terms=<n>, fv_bad_case=<n>`
  - `- [ ] links: missing_images=<n>, missing_links=<n>` (only if links_report.json present)
  - `- [ ] images_render: not_done=<n>`
- Adds a summary block at the top: totals, modules with gaps, top 10 modules by issue count.
- Prints a one-line summary to stdout:
  - `TODO modules=<N> with_gaps=<K> actions=<M> written=build/gaps_todo.md`

Exit Codes
- `0` on success.
- `1` on I/O/parse errors.

Typical Workflow
1) Generate/refresh artifacts:
   - `dart run tooling/content_gap_report.dart --json build/gaps.json`
   - `dart run tooling/term_lint.dart --json build/term_lint.json --quiet`
   - `dart run tooling/check_links.dart --json build/links_report.json || true`
2) Build the TODO plan:
   - `dart run tooling/gaps_todo.dart`
3) Tackle the highest-issue modules from the top summary.

