Run the NEXT detector:
dart test -r expanded test/curriculum_status_test.dart

Read: NEXT: <moduleId>

Do:

Add lib/packs/<moduleId>_loader.dart (minimal stub pack; no content)

Append "<moduleId>" to modules_done in curriculum_status.json (append-only)

Checks:

dart format (no diffs) • dart analyze (clean)

Merge PR. Repeat.

Notes:

Touch 1-2 code files + the status file. Enum append-only only if required.

Use actionsMap and subtitlePrefix; no legacy switches.
