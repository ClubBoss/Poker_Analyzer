# Poker AI Analyzer

[![Demo APK Build](https://github.com/OWNER/REPO/actions/workflows/demo_build.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/demo_build.yml)

Poker AI Analyzer helps analyze and train poker decision making. The app lets you create hands, play training packs and track statistics.

## Getting Started

1. Install Flutter 3.0 or higher.
2. Run `flutter pub get` to install dependencies.
3. Launch with `flutter run`.

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


## Converter plug-ins

Custom import and export formats can be added by implementing the
`ConverterPlugin` interface. Each plug-in exposes a `formatId` and a
human readable `description` so the UI can list available options. Before an
export occurs, the application calls `validateForExport(formatId, hand)` which
delegates to the plug-in's optional `validate` method. Returning a string from
`validate` will reject the hand for export and surface the message to the user,
while returning `null` allows the export to proceed.

![screenshot](flutter_01.png)

## Future plans

Cloud sync for saved hands and sessions will be added later.

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
