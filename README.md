# Poker AI Analyzer

Poker AI Analyzer helps analyze and train poker decision making. The app lets you create hands, play training packs and track statistics.

## Getting Started

1. Install Flutter 3.0 or higher.
2. Run `flutter pub get` to install dependencies.
3. Launch with `flutter run`.

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
