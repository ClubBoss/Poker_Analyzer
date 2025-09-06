Green Run

Purpose
- One-click local "make it green".

What it runs
- dart run tooling/ascii_sanitize.dart --fix
- dart run tooling/term_lint.dart --fix --fix-scope=md+jsonl --json build/term_lint.json --quiet
- dart run tooling/demos_steps_fix.dart --fix
- dart run tooling/demos_count_fix.dart --fix
- dart run tooling/drills_json_repair.dart --fix || true
- dart run tooling/drills_seed_missing.dart --write
- dart run tooling/theory_scaffold_fix.dart --fix
- dart run tooling/theory_wordcount_balance.dart --fix --force --aggressive
- make images
- dart run tooling/sync_image_status.dart
- dart run tooling/derive_allowlists.dart --write --clear
- dart run tooling/content_gap_report.dart --json build/gaps.json
- dart run tooling/explain_gap_details.dart --json build/gap_details.json
- dart run tooling/demos_steps_lint.dart --json build/demos_steps.json --quiet
- dart run tooling/build_search_index.dart --json build/search_index.json
- dart run tooling/build_see_also.dart --json build/see_also.json
- dart run tooling/link_see_also_in_theory.dart
- dart run tooling/check_links.dart --json build/links_report.json
- dart run tooling/pre_release_check.dart
- dart run tooling/export_ui_assets.dart --out build/ui_assets --recompute
- make snapshots

Safety notes
- Edits content deterministically; review diffs.

Usage
- make green-run

Outputs
- build/pre_release_check.txt
- ci/snapshots/
