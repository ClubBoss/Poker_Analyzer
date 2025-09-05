Content GAP Report

Purpose
- Generate a deterministic, grep‑friendly table of content gaps across modules under `content/*/v1/`.
- Helps drive Fill and Polish phases by surfacing missing sections, out‑of‑range word counts, image placeholders, and JSONL issues.

CLI Usage
- Run the tool from repo root:
  - `dart run tooling/content_gap_report.dart`
  - Filter to a single module (optional):
    - `dart run tooling/content_gap_report.dart core_board_textures`

Output
- ASCII table, one row per module, with header:
  - `module|missing_sections|wordcount_out_of_range|images_missing|demo_count_bad|drill_count_bad|invalid_spot_kind|invalid_targets|duplicate_ids|off_tree_sizes`
- Booleans are `0` or `1`. `missing_sections` is `-` or a comma‑separated list.
- Exit code is `0` when no gaps, `1` if any module has gaps.

Allowlist Semantics
- Spot kind allowlist: `tooling/allowlists/spotkind_allowlist_<module>.txt`
- Target tokens allowlist: `tooling/allowlists/target_tokens_allowlist_<module>.txt`
- If an allowlist file is missing, its validation is skipped for that module.
- Sentinel `none` inside an allowlist disables validation for that module (same as missing file).
- `invalid_spot_kind` and `invalid_targets` only appear when the respective allowlist exists (and is not `none`) and flags real issues.
 - Demos token sanity is only enforced when a non-empty target tokens allowlist exists. If the file is missing/empty or contains exactly `none`, token sanity is skipped for demos in that module.

Typical Local Commands (while wider repo has parse errors)
- Format only this file:
  - `dart format tooling/content_gap_report.dart`
- Run the GAP report:
  - `dart run tooling/content_gap_report.dart`
  - `dart run tooling/content_gap_report.dart core_board_textures`
