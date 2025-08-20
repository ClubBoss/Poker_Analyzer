PR Checklist (tick all before merge)

Tiny diff (1-2 code files), ASCII-only, no new deps
Exactly 2 files touched (loader or equivalent) + curriculum_status.json update
dart format — no diffs
dart analyze — clean
SpotKind enum unchanged except append-at-end (if touched)
actionsMap / subtitlePrefix updated (if applicable)
Canonical guard untouched, single site
Tests updated/added (pure-Dart where possible)
Telemetry considered (if user-visible behavior)
Status updated — appended this module id to curriculum_status.json (modules_done, append-only) in the same PR
