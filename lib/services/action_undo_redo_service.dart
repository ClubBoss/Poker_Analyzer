import '../models/card_model.dart';
import '../models/action_entry.dart';
import 'action_sync_service.dart';
import 'board_manager_service.dart';
import 'playback_manager_service.dart';
import 'action_tag_service.dart';
import 'action_history_service.dart';
import 'transition_lock_service.dart';

class ActionUndoRedoService {
  final ActionSyncService actionSync;
  final BoardManagerService boardManager;
  final PlaybackManagerService playbackManager;
  final ActionTagService actionTagService;
  final ActionHistoryService actionHistory;
  final TransitionLockService lockService;

  ActionUndoRedoService({
    required this.actionSync,
    required this.boardManager,
    required this.playbackManager,
    required this.actionTagService,
    required this.actionHistory,
    required this.lockService,
  });

  ActionSnapshot _currentSnapshot() => actionSync.buildSnapshot(
        List<CardModel>.from(boardManager.boardCards),
        actionHistory.expandedStreets,
      );

  void recordSnapshot() {
    actionSync.recordSnapshot(_currentSnapshot());
  }

  void resetHistory() {
    actionSync.clearAnalyzerActions();
  }

  void _applySnapshot(ActionSnapshot snap) {
    final prevStreet = boardManager.currentStreet;
    actionSync.restoreSnapshot(snap);
    actionHistory.setExpandedStreets(snap.expandedStreets);
    boardManager.setBoardCards(snap.board);
    if (boardManager.currentStreet != prevStreet) {
      boardManager.startBoardTransition();
    }
  }

  void undo() {
    if (lockService.undoRedoTransitionLock || lockService.isLocked) return;
    boardManager.cancelBoardReveal();
    final result = actionSync.undo(_currentSnapshot());
    if (result.entry == null && result.snapshot == null) return;

    final op = result.entry;
    final snap = result.snapshot;
    if (op != null) {
      switch (op.type) {
        case ActionChangeType.add:
          actionTagService.updateAfterActionRemoval(
              op.newEntry!.playerIndex, actionSync.analyzerActions);
          break;
        case ActionChangeType.edit:
          actionTagService.updateForAction(op.oldEntry!);
          break;
        case ActionChangeType.delete:
          actionTagService.updateForAction(op.oldEntry!);
          break;
      }
      boardManager.changeStreet(op.prevStreet);
    }
    if (snap != null) {
      _applySnapshot(snap);
    }
    playbackManager.updatePlaybackState();
    actionHistory.autoCollapseStreets(actionSync.analyzerActions);
    boardManager.startBoardTransition();
  }

  void redo() {
    if (lockService.undoRedoTransitionLock || lockService.isLocked) return;
    boardManager.cancelBoardReveal();
    final result = actionSync.redo(_currentSnapshot());
    if (result.entry == null && result.snapshot == null) return;

    final op = result.entry;
    final snap = result.snapshot;
    if (op != null) {
      switch (op.type) {
        case ActionChangeType.add:
          actionTagService.updateForAction(op.newEntry!);
          break;
        case ActionChangeType.edit:
          actionTagService.updateForAction(op.newEntry!);
          break;
        case ActionChangeType.delete:
          actionTagService.updateAfterActionRemoval(
              op.oldEntry!.playerIndex, actionSync.analyzerActions);
          break;
      }
      boardManager.changeStreet(op.newStreet);
    }
    if (snap != null) {
      _applySnapshot(snap);
    }
    playbackManager.updatePlaybackState();
    actionHistory.autoCollapseStreets(actionSync.analyzerActions);
    boardManager.startBoardTransition();
  }
}
