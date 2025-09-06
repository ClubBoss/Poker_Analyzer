Snapshots

Purpose
- Collect selected build outputs for quick inspection.

Files
- pre_release_check.txt
- gaps.json
- term_lint.json
- links_report.json
- demos_steps.json
- gap_details.json
- ui_assets/manifest.json

Local Usage
- make snapshots
- make snapshots-clean

CI
- Content CI uploads these files as the snapshots artifact.
- CI publishes the snapshots artifact using path pattern ci/snapshots/**.
