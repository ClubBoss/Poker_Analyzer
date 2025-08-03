# Cleanup Candidates

This document lists files and directories that appear unused in production code and may be candidates for removal or relocation to a legacy area. They are grouped by category as part of the audit for unused or outdated assets, test data, and developer tools.

## Images
- `assets/images/` — empty directory; no referenced images.

## Mocks / Test Data
- `tool/example_spots/btn_10bb.json` — sample spot file not referenced in production code.
- `tests/` — duplicate test directory; Dart/Flutter tests run from `test/` by default.
- `fix_ci.txt` — empty log file not used by the project.
- `fix_log.txt` — log file only referenced by `tools/fix_training_pack_errors.dart`.

## Dev Tools / Scripts
- `tools/architecture_snapshot.dart` — standalone script without references.
- `tools/fix_training_pack_errors.dart` — script not referenced by other code.
- `tools/path_yaml_visualizer.html` — helper HTML page only linked in docs.
- `tools/publisher_dashboard.html` — helper HTML page only linked in docs.
- `tools/validate_training_content.dart` — script only mentioned in docs.

## Legacy Screens
No dedicated legacy UI screens or directories (e.g., `legacy_ui/`, `old_*`) were found.

## Miscellaneous
- `ci_deploy_key` and `ci_deploy_key.pub` — unused CI deploy keys not referenced elsewhere.

These items can be considered for removal to reduce repository size and improve CI performance. Further verification is recommended before deletion.
