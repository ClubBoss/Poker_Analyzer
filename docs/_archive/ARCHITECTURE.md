# Architecture Overview

This document summarizes the current set of services used by the Poker Analyzer application and their responsibilities. Services encapsulate business logic, persistence and cross-widget coordination. UI screens such as `PokerAnalyzerScreen` interact with these services but do not implement serialization or lower-level state management directly.

## Services

- **ActionEditingService** – modifies analyzer actions while keeping dependent services (undo/redo, tags, playback, folded players, board state) in sync.
- **ActionHistoryService** – stores actions grouped by street for quick history queries.
- **ActionSyncService** – central event bus for actions; synchronizes playback index, folded players and stack manager.
- **ActionTagService** – manages per-player action tags and serializes them with hands.
- **BackupManagerService** – creates, loads and cleans up evaluation queue backups.
- **BackupFileManager** – low level helper used by `BackupManagerService` for file operations.
- **EvaluationQueueSerializer** – encodes/decodes `ActionEvaluationRequest` queue states.
- **BoardEditingService** – validates board edits and warns about inconsistent card choices.
- **BoardManagerService** – controls board street transitions, visible cards and locks during playback.
- **BoardRevealService** – animates board card reveal sequences while respecting transition locks.
- **BoardSyncService** – keeps board cards consistent with actions and player state.
- **CurrentHandContextService** – holds temporary UI state such as the current hand name and comment fields.
- **DailyHandService** – manages daily training hands history.
- **DebugPanelPreferences** – persists debug panel settings like processing delay and filters.
- **DebugSnapshotService** – saves and loads evaluation queue snapshots for debugging.
- **EvaluationExecutorService** – executes a single evaluation request (stub implementation).
- **EvaluationProcessingService** – processes the evaluation queue with optional backups and snapshots.
- **EvaluationQueueImportExportService** – imports/exports evaluation queue data to files, clipboard or archives.
- **EvaluationQueueService** – stores pending/completed evaluation requests and persists them to disk.
- **FoldedPlayersService** – tracks which players have folded and recomputes from actions when needed.
- **HandRestoreService** – rebuilds runtime state from a saved hand including stacks and actions.
- **PlaybackManagerService** – controls playback of actions and updates pot sizes and animations.
- **PlaybackService** – low level timer based playback engine used by `PlaybackManagerService`.
- **PlayerEditingService** – updates player information and keeps stacks and playback in sync.
- **PlayerManagerService** – owns player cards, stacks and profile data; delegates profile serialization to `PlayerProfileImportExportService`.
- **PlayerProfileImportExportService** – serializes/deserializes player profile data and handles clipboard/file operations.
- **PlayerProfileService** – stores player positions, types and revealed cards.
- **PotHistoryService** – records pot sizes per playback index.
- **PotSyncService** – computes pot sizes and effective stacks from actions and stack manager state.
- **RetryEvaluationService** – retries failed evaluation requests until they succeed or the attempt limit is reached.
- **SavedHandImportExportService** – builds `SavedHand` objects from current services and supports import/export to clipboard or files.
- **SavedHandManagerService** – manages the list of saved hands and exposes tag filtering utilities.
- **SavedHandService** – simple local storage for hands using shared preferences.
- **SavedHandStorageService** – file based storage for hands, used by `SavedHandManagerService`.
- **SnapshotService** – generic helper to persist evaluation snapshots to disk.
- **StackManagerService** – tracks current stack sizes and investments; works with `PotSyncService`.
- **TrainingImportExportService** – serializes training spots to/from clipboard or files.
- **TrainingPackStorageService** – manages persisted training packs on disk.
- **TransitionHistoryService** – records board transition lock snapshots to enable undo/redo of transitions.
- **TransitionLockService** – global lock manager for board transitions and generic critical sections.
- **UndoRedoService** – captures snapshots of the full analyzer state and restores them on undo/redo actions.
- **UserPreferencesService** – persists simple UI preferences like animation toggles.

These services expose `toJson`/`fromJson` helpers where serialization is required, keeping all persistence logic outside of UI screens. The main analyzer screen coordinates user interactions and delegates state changes to these services, ensuring a clean separation between UI and business logic.
