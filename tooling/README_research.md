Research Draft Quick Check

Purpose
- Validate a draft content folder (outside this repo) before merge/import.
- Catches structural gaps quickly without relying on repo allowlists.

Usage
- Unzip any archives first (zips are not supported by the tool).
- Run the quick check, pointing to the draft root:
  - `dart run tooling/research_quickcheck.dart /abs/path/to/draft_root`
- JSON output + quiet mode:
  - `dart run tooling/research_quickcheck.dart /abs/path/to/draft_root --json /tmp/research_gaps.json --quiet`
Run on draft folder
- Makefile wrapper (prints table and writes build/research_gaps.json):
  - `make research-check DRAFT=/abs/path/to/draft_root`
- Inspect the JSON:
  - `cat build/research_gaps.json`


Expected Layout
- `<root>/content/<module>/v1/` containing:
  - `theory.md`
  - `demos.jsonl`
  - `drills.jsonl`

Checks (per module)
- theory.md: ASCII-only; 400-700 words; required headers: What it is, Why it matters, Rules of thumb, Mini example, Common mistakes, Mini-glossary, Contrast; at least one `[[IMAGE:` marker.
- demos.jsonl: 2-3 lines; each line valid JSON; has `id` and `spot_kind`; `steps` length >= 4; token sanity hit on any of: `small_cbet_33, half_pot_50, big_bet_75, probe_turns, delay_turn, double_barrel_good, triple_barrel_scare, call, fold, overfold_exploit`.
- drills.jsonl: 10-20 lines; each line valid JSON; `id` string; `targets` array present; no off-tree sizes (only 33/50/75 numeric suffixes allowed).

Output
- Table printed to stdout (stable):
  - `module|missing_sections|wordcount_out_of_range|images_missing|demo_count_bad|drill_count_bad|duplicate_ids|off_tree_sizes`
- Flags: `--json <path>` writes `{"rows":[...],"totals":{...}}`; `--quiet` suppresses stdout. Exit code is 0 if clean, 1 if any gaps.

Diff vs repo-scoped content_gap_report.dart
- Path-scoped; does not use repo allowlists; focuses on draft structural sanity only.
- Keys limited to structural gaps relevant for pre-merge research batches.

