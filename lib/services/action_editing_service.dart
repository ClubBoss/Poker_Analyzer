import '../models/action_entry.dart';
import '../models/player_model.dart';
import '../helpers/action_formatting_helper.dart';
import '../widgets/player_zone_widget.dart';
import 'action_sync_service.dart';
import 'undo_redo_service.dart';
import 'action_tag_service.dart';
import 'playback_manager_service.dart';
import 'folded_players_service.dart';
import 'all_in_players_service.dart';
import 'board_manager_service.dart';
import 'board_sync_service.dart';
import 'action_history_service.dart';
import 'player_manager_service.dart';

/// Centralized service for modifying analyzer actions and keeping related
/// state in sync across the application.
class ActionEditingService {
  final ActionSyncService actionSync;
  final UndoRedoService undoRedo;
  final ActionTagService actionTag;
  final PlaybackManagerService playbackManager;
  final FoldedPlayersService foldedPlayers;
  final AllInPlayersService allInPlayers;
  final BoardManagerService boardManager;
  final BoardSyncService boardSync;
  final ActionHistoryService actionHistory;
  final PlayerManagerService playerManager;
  final void Function(ActionEntry entry)? triggerCenterChip;
  final void Function(ActionEntry entry)? playChipAnimation;
  final PlayerZoneRegistry playerZoneRegistry;

  ActionEditingService({
    required this.actionSync,
    required this.undoRedo,
    required this.actionTag,
    required this.playbackManager,
    required this.foldedPlayers,
    required this.allInPlayers,
    required this.boardManager,
    required this.boardSync,
    required this.actionHistory,
    required this.playerManager,
    this.triggerCenterChip,
    this.playChipAnimation,
    required this.playerZoneRegistry,
  });

  List<ActionEntry> get actions => actionSync.analyzerActions;
  int get currentStreet => boardManager.currentStreet;
  List<PlayerModel> get players => playerManager.players;

  /// Append [entry] to the end of the actions list.
  void addAction(ActionEntry entry, {bool recordHistory = true}) {
    insertAction(actions.length, entry, recordHistory: recordHistory);
  }

  /// Insert [entry] at [index] in the actions list.
  void insertAction(int index, ActionEntry entry,
      {bool recordHistory = true}) {
    final prevStreet = currentStreet;
    final inferred = boardSync.inferBoardStreet();
    if (inferred > currentStreet) {
      boardManager.boardStreet = inferred;
      boardManager.changeStreet(inferred);
    }
    if (entry.street != currentStreet) {
      entry = ActionEntry(currentStreet, entry.playerIndex, entry.action,
          amount: entry.amount, generated: entry.generated);
    }
    actionSync.analyzerActions.insert(index, entry);
    if (recordHistory) {
      actionSync.recordHistory(ActionHistoryEntry(ActionChangeType.add, index,
          newEntry: entry, prevStreet: prevStreet, newStreet: currentStreet));
    }
    actionSync.foldedPlayers?.addFromAction(entry);
    actionSync.allInPlayers?.addFromAction(entry);
    actionSync.syncStacks();
    actionSync.notifyListeners();
    actionHistory.addStreet(entry.street);
    actionHistory.updateHistory(actionSync.analyzerActions,
        visibleCount: playbackManager.playbackIndex);
    actionTag.updateForAction(entry);
    setPlayerLastAction(
      playerZoneRegistry,
      players[entry.playerIndex].name,
      ActionFormattingHelper.formatLastAction(entry),
      ActionFormattingHelper.actionColor(entry.action),
      entry.action,
      entry.amount,
    );
    if (recordHistory) {
      triggerCenterChip?.call(entry);
      playChipAnimation?.call(entry);
    }
    if (playbackManager.playbackIndex > actions.length) {
      playbackManager.seek(actions.length);
    }
    playbackManager.updatePlaybackState();
    _autoAdvanceStreetIfComplete(entry.street);
    if (recordHistory) {
      undoRedo.recordSnapshot();
    }
  }

  /// Replace the action at [index] with [entry].
  void editAction(int index, ActionEntry entry, {bool recordHistory = true}) {
    if (index < 0 || index >= actions.length) return;
    if (entry.street != currentStreet) {
      entry = ActionEntry(currentStreet, entry.playerIndex, entry.action,
          amount: entry.amount, generated: entry.generated);
    }
    final previous = actions[index];
    actionSync.analyzerActions[index] = entry;
    if (recordHistory) {
      actionSync.recordHistory(ActionHistoryEntry(ActionChangeType.edit, index,
          oldEntry: previous,
          newEntry: entry,
          prevStreet: currentStreet,
          newStreet: currentStreet));
    }
    actionSync.foldedPlayers?.editAction(previous, entry, actionSync.analyzerActions);
    actionSync.allInPlayers?.editAction(previous, entry, actionSync.analyzerActions);
    actionSync.syncStacks();
    actionSync.notifyListeners();
    actionTag.updateForAction(entry);
    setPlayerLastAction(
      playerZoneRegistry,
      players[entry.playerIndex].name,
      ActionFormattingHelper.formatLastAction(entry),
      ActionFormattingHelper.actionColor(entry.action),
      entry.action,
      entry.amount,
    );
    if (recordHistory) {
      triggerCenterChip?.call(entry);
      playChipAnimation?.call(entry);
    }
    if (entry.action == 'fold') {
      _removeFutureActionsForPlayer(entry.playerIndex, entry.street, index);
    }
    playbackManager.updatePlaybackState();
    actionHistory.updateHistory(actionSync.analyzerActions,
        visibleCount: playbackManager.playbackIndex);
    _autoAdvanceStreetIfComplete(entry.street);
    if (recordHistory) {
      undoRedo.recordSnapshot();
    }
  }

  /// Remove the action at [index].
  void deleteAction(int index, {bool recordHistory = true}) {
    if (index < 0 || index >= actions.length) return;
    final removed = actions[index];
    actionSync.analyzerActions.removeAt(index);
    if (recordHistory) {
      actionSync.recordHistory(ActionHistoryEntry(ActionChangeType.delete, index,
          oldEntry: removed,
          prevStreet: currentStreet,
          newStreet: currentStreet));
    }
    actionSync.foldedPlayers?.removeFromAction(removed, actionSync.analyzerActions);
    actionSync.allInPlayers?.removeFromAction(removed, actionSync.analyzerActions);
    actionSync.syncStacks();
    actionSync.notifyListeners();
    if (playbackManager.playbackIndex > actions.length) {
      playbackManager.seek(actions.length);
    }
    actionTag.updateAfterActionRemoval(removed.playerIndex, actions);
    actionHistory.updateHistory(actionSync.analyzerActions,
        visibleCount: playbackManager.playbackIndex);
    actionHistory.autoCollapseStreets(actions);
    playbackManager.updatePlaybackState();
    if (recordHistory) {
      undoRedo.recordSnapshot();
    }
  }

  /// Move an action from [oldIndex] to [newIndex].
  void reorderAction(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= actions.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex >= actions.length) newIndex = actions.length - 1;
    final entry = actionSync.analyzerActions.removeAt(oldIndex);
    actionSync.analyzerActions.insert(newIndex, entry);
    actionTag.recompute(actionSync.analyzerActions);
    actionSync.syncStacks();
    actionSync.notifyListeners();
    playbackManager.updatePlaybackState();
    actionHistory.updateHistory(actionSync.analyzerActions,
        visibleCount: playbackManager.playbackIndex);
    actionHistory.autoCollapseStreets(actions);
    undoRedo.recordSnapshot();
  }

  /// Remove all future actions for [playerIndex] starting from [fromIndex]
  /// on [street]. This is typically called after a fold or when auto-folds
  /// are inserted.
  void removeFutureActionsForPlayer(
      int playerIndex, int street, int fromIndex) {
    _removeFutureActionsForPlayer(playerIndex, street, fromIndex);
    actionHistory.updateHistory(actionSync.analyzerActions,
        visibleCount: playbackManager.playbackIndex);
    actionHistory.autoCollapseStreets(actions);
  }

  // ----- Helpers -----

  bool _isStreetComplete(int street) {
    final active = <int>{};
    for (int i = 0; i < playerManager.numberOfPlayers; i++) {
      if (!foldedPlayers.isPlayerFolded(i)) active.add(i);
    }
    if (active.length <= 1) return true;
    final acted = actions
        .where((a) => a.street == street)
        .map((a) => a.playerIndex)
        .toSet();
    return active.difference(acted).isEmpty;
  }

  void _autoAdvanceStreetIfComplete(int street) {
    if (street != currentStreet || street >= 3) return;
    if (!_isStreetComplete(street)) return;
    if (!boardManager.canAdvanceStreet()) return;
    boardManager.advanceStreet();
    undoRedo.recordSnapshot();
  }

  void _removeFutureActionsForPlayer(
      int playerIndex, int street, int fromIndex) {
    final toRemove = <int>[];
    for (int i = actions.length - 1; i > fromIndex; i--) {
      final a = actions[i];
      if (a.playerIndex == playerIndex && a.street >= street) {
        toRemove.add(i);
      }
    }
    if (toRemove.isEmpty) return;
    for (final idx in toRemove) {
      final removed = actions[idx];
      actionSync.analyzerActions.removeAt(idx);
      actionSync.foldedPlayers?.removeFromAction(removed, actionSync.analyzerActions);
      actionSync.allInPlayers?.removeFromAction(removed, actionSync.analyzerActions);
    }
    actionSync.syncStacks();
    actionSync.notifyListeners();
    if (playbackManager.playbackIndex > actions.length) {
      playbackManager.seek(actions.length);
    }
    actionTag.updateAfterActionRemoval(playerIndex, actions);
    playbackManager.updatePlaybackState();
    actionHistory.updateHistory(actionSync.analyzerActions,
        visibleCount: playbackManager.playbackIndex);
    actionHistory.autoCollapseStreets(actions);
  }
}
