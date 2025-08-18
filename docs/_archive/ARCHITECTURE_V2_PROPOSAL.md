# Architecture 2.0 Proposal

This document outlines potential improvements for the next major revision of the Poker Analyzer architecture. The current service-based design proved effective; the following ideas build on top of it without breaking existing modules.

## Plugin-Based Services

- **Service Registry** - A discovery mechanism where the core analyzer registers and loads optional plugins at runtime.
- **Plugin Contract** - Define an interface that allows third-party packages to provide additional services (e.g., custom evaluators or trackers) without modifying the main app.
- **Isolation** - Plugins communicate only through the service registry and cannot access UI components directly. All serialization remains centralized.

## Modular UI Components

- **Widget Packages** - Extract generic widgets (action editors, training views) into standalone packages so plugins or other apps can reuse them.
- **Navigation Manager** - Replace large screen classes with smaller composable routes managed by a central navigation service.
- **State Scope Widgets** - Provide inherited widgets for scoped state (e.g., current hand context) to simplify screen composition.

## Advanced Undo/Redo

- **Diff Snapshots** - Store full state diffs instead of entire serialized objects. This reduces memory usage and speeds up history traversal.
- **Command Pipeline** - Represent user actions as commands that produce diffs; undo/redo simply replays these commands.
- **History Storage** - Allow saving undo stacks to disk for long sessions and restoring them when reloading a hand.

## Flexible Import/Export Pipelines

- **Converter Plugins** - Support external hand converters via the plugin system. Each converter translates between Poker Analyzer format and third-party data.
- **Streamed Parsing** - Large file imports should parse incrementally to keep the UI responsive.
- **Export Filters** - Provide hooks to transform exported hands based on user-specified options (omit private notes, anonymize player names, etc.).

## Suggested Modules

1. `plugins/`
   - `service_registry.dart`
   - `plugin_interface.dart`
2. `ui_packages/`
   - `action_editor_widgets/`
   - `training_module_widgets/`
3. `undo_history/`
   - `diff_engine.dart`
   - `command_model.dart`
4. `import_export/`
   - `converter_registry.dart`
   - `stream_parser.dart`
   - `export_filters.dart`

These modules are only a starting point. Version 2.0 can adopt them gradually while keeping the existing services stable.
