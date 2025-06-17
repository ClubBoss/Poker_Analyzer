# Architecture 2.0 Proposal

The current Poker Analyzer architecture isolates services and centralizes serialization. The next major version can extend this foundation with additional modularity, state tracking and external integrations.

## Goals
- Provide a plug‑in mechanism so new services can be added without modifying core packages.
- Break the UI into modular components that can be embedded in other Flutter apps or reused across screens.
- Enable advanced undo/redo with state diffs for better debugging and user interaction history.
- Allow importing hand histories from third‑party converters through a flexible pipeline.

## Proposed Modules

### Plugin Runtime
A lightweight registry that discovers plug‑in packages at runtime and wires them into existing services. Each plug‑in defines:
- service bindings that expose new functionality
- optional UI widgets to configure or launch the plug‑in
- serialization hooks if persistent data is required

### Modular UI Components
Refactor existing screens into independent widgets:
- `HandEditorModule` – hand creation and editing flow
- `TrainingModule` – training pack playback
- `PlayerProfileModule` – profile editing and stats
- `EvaluationQueueModule` – evaluation history and retries

Each module would manage its own state and expose a minimal public API. Modules could be loaded dynamically or embedded in external applications.

### State Diff Undo/Redo
Replace snapshot‑based undo/redo with a diff engine that captures only changed fields across services:
- Compute diffs when actions modify services
- Store diffs in the `TransitionHistoryService`
- Apply diffs to roll back/forward without full snapshots

This reduces memory usage and enables advanced tooling that visualizes what changed between steps.

### External Hand Conversion Pipeline
Introduce a `HandConversionPipeline` that processes raw text or file formats into `SavedHand` objects. Stages include:
1. **Source Reader** – reads hands from clipboard, local files or remote sources
2. **Converter Plugins** – parse specific hand history formats (e.g., PokerStars, GGPoker)
3. **Validation Stage** – ensures the resulting actions are consistent
4. **Import Stage** – feeds validated hands into existing services (`SavedHandImportExportService`)

Converters can be added as plug‑ins so users install only the formats they need.

## Summary
Architecture 2.0 aims to keep the clean separation of services while adding extension points and more granular state tracking. By isolating modules and providing plug‑in APIs, the Poker Analyzer can grow beyond the current monolithic design and integrate with external hand history tools.
