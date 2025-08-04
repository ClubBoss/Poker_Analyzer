# Poker AI Analyzer
<!-- 30/40 (Advanced Insights) -->

[![Demo APK Build](https://github.com/ClubBoss/Poker_Analyzer/actions/workflows/demo_build.yml/badge.svg)](https://github.com/ClubBoss/Poker_Analyzer/actions/workflows/demo_build.yml)

Poker AI Analyzer helps analyze and train poker decision making. The app lets you create hands, play training packs and track statistics.

## Project Vision

Poker Analyzer aims to be a universal tool for improving decision making at the table. It analyzes push/fold situations with EV and ICM metrics, provides targeted training packs and shows mistakes after each session. A streamlined interface with dynamic progress charts and achievement goals keeps players motivated. Cloud sync, data export and mobile support let users train anywhere. Whether a beginner or seasoned pro, the app adapts to individual weaknesses and tracks growth over time.


## Getting Started

1. Install Flutter 3.0 or higher.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter gen-l10n` to generate localization files.
4. Precompile training packs with `dart tools/precompile_all_packs.dart`.
5. Launch with `flutter run`.

## Demo Build

The project includes a lightweight demo entry point for showcasing the
analyzer without the full feature set. Run the demo in debug mode with:

```bash
flutter run -t main.dart
```

To generate a production APK for the demo use:

```bash
flutter build apk --target=main.dart
```

This build is useful for previews, demonstrations and other scenarios
where the complete UI and logic are not required.

## Project Structure

- `lib/` – application source code
  - `screens/` – UI screens
  - `models/` – plain models
  - `services/` – business logic and persistence (includes `HandRestoreService` to rebuild runtime state and `BackupManagerService` for queue backups)
  - `helpers/` – reusable helper functions
- `assets/` – images and other assets
- `test/` – unit tests

## Features

- Save and load played hands
- View training history and overall statistics
- See mistake counts grouped by tag to identify weak spots
- Explore mistake counts by street and position for targeted review
- View accuracy percentages grouped by tag, street and position to gauge relative weakness
- Export mistake reports as PDF for sharing
- Share your results via exported files
- Optional checkbox lets you export only sessions that contain at least three tags
- Pending evaluations are stored in saved hand exports so queued
  action analysis persists when reloading a session, ensuring consistent
  playback even after closing the app
- Automatic evaluation queue backups run every 15 minutes and keep only
  the 50 most recent files to save storage
- Import and export the full evaluation queue state through the debug panel
- Bulk import evaluation snapshots from the debug panel
- Import and export hand histories through plug-in converters
  with metadata and validation so incompatible hands can be
  detected before export
- Batch operations in the Training Spot list allow applying the current
  difficulty and rating filters to all visible spots or deleting them in
  one step with confirmation dialogs.
- Opponent folds animate their cards sliding down with a fade-out. The hero's
  cards disappear instantly without animation for clarity.
- Inline graph editor lets admins build learning paths with theory lessons and
  branching practice stages.


## Converter plug-ins

Custom import and export formats can be added by implementing the
`ConverterPlugin` interface. Each plug-in exposes a `formatId` and a
human readable `description` so the UI can list available options. Before an
export occurs, the application calls `validateForExport(formatId, hand)` which
delegates to the plug-in's optional `validate` method. Returning a string from
`validate` will reject the hand for export and surface the message to the user,
while returning `null` allows the export to proceed.

- PartyPoker Converter plug-in adds support for Partypoker hand history files.

Подробнее о подключении сторонних модулей описано в [docs/plugins](docs/plugins/README.md).
Разработчикам плагинов посвящено руководство [PLUGIN_DEV_GUIDE](docs/plugins/PLUGIN_DEV_GUIDE.md).

## Plug-ins

See [USER_GUIDE](docs/plugins/USER_GUIDE.md) for installation and activation.

![screenshot](flutter_01.png)

## Future plans

The app now syncs saved hands and session data with Firestore.

## Branch naming

All new development branches must start with the `codex/` prefix followed by a
short task description using ASCII characters only. Replace spaces with hyphens.
For example:

```
codex/add-activeplayerindex-debug-panel
```

Avoid Cyrillic, special characters or other Unicode symbols in branch names.

## Troubleshooting

If Git reports `The head ref may contain hidden characters`, the `.git/HEAD` or
a ref file might contain invisible control characters. Run the helper script
below to scan the repository:

```bash
tools/check_head_refs.sh
```

If the script finds issues, rewrite the affected file. For example, to reset the
`HEAD` ref you can run:

```bash
echo 'ref: refs/heads/main' > .git/HEAD
```

This removes hidden characters and resolves the error.

## Content Validation

Run the training content validator to lint YAML packs and ensure schema
correctness:

```bash
dart tools/validate_training_content.dart --fix
```

Use `--ci` to exit with a non-zero code on errors.

## Precompile Training Packs

Regenerate the precompiled YAML packs before running the app or building a release:

```bash
dart tools/precompile_all_packs.dart
```

## Path YAML Visualizer

The `tools` directory includes a small web tool for previewing a compiled
`path.yaml` without running the Flutter app. Open
`tools/path_yaml_visualizer.html` in a browser and drop a YAML file onto the
page. The viewer renders a table of stages and subStages with their titles,
`packId` values and unlock conditions. Rows are highlighted if a `packId` is
missing or an `unlockCondition.dependsOn` refers to an unknown stage.

## Pack Library Publisher Dashboard

For a no-code publishing workflow open `tools/publisher_dashboard.html` in a
browser. The page lets you upload a directory of training packs and a path spec
file, then run the `publish_content.dart` script via a local server or Web
Assembly build. Buttons are provided for validation, full publish or dry-run
modes. After processing the dashboard shows how many packs and paths were
published or skipped and provides links to the generated `index.json` and
compiled `path.yaml` files.
