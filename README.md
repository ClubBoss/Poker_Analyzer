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
  - `services/` – business logic and persistence
  - `helpers/` – reusable helper functions
- `assets/` – images and other assets
- `test/` – unit tests

## Features

- Save and load played hands
- View training history and overall statistics
- Share your results via exported files

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
