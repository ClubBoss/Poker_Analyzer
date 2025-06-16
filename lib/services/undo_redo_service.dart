import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/saved_hand.dart';
import 'action_sync_service.dart';
import 'board_manager_service.dart';
import 'board_reveal_service.dart';
import 'pot_sync_service.dart';
import 'playback_manager_service.dart';
import 'action_tag_service.dart';
import 'action_history_service.dart';
import 'current_hand_context_service.dart';
import 'folded_players_service.dart';
import 'player_manager_service.dart';
import 'transition_lock_service.dart';

/// Manages undo/redo snapshots for the full analyzer state.
class UndoRedoService {
  final ActionSyncService actionSync;
  final BoardManagerService boardManager;
  final PlaybackManagerService playbackManager;
  final PlayerManagerService playerManager;
  final CurrentHandContextService handContext;
  final ActionTagService actionTagService;
  final ActionHistoryService actionHistory;
  final FoldedPlayersService foldedPlayers;
  final BoardRevealService boardReveal;
  final PotSyncService potSync;
  final TransitionLockService lockService;

  UndoRedoService({
    required this.actionSync,
    required this.boardManager,
    required this.playbackManager,
    required this.playerManager,
    required this.handContext,
    required this.actionTagService,
    required this.actionHistory,
    required this.foldedPlayers,
    required this.boardReveal,
    required this.potSync,
    required this.lockService,
  });

  final List<SavedHand> _undoStack = [];
  final List<SavedHand> _redoStack = [];

  SavedHand _currentSnapshot() {
    final stackService = playbackManager.stackService;
    final reveal = boardReveal.toJson();
    potSync.updateEffectiveStacks(
        actionSync.analyzerActions, playerManager.numberOfPlayers);
    final hand = SavedHand(
      name: handContext.currentHandName ?? '',
      heroIndex: playerManager.heroIndex,
      heroPosition: playerManager.heroPosition,
      numberOfPlayers: playerManager.numberOfPlayers,
      playerCards: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          List<CardModel>.from(playerManager.playerCards[i])
      ],
      boardCards: List<CardModel>.from(playerManager.boardCards),
      boardStreet: boardManager.boardStreet,
      revealedCards: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          [for (final c in playerManager.players[i].revealedCards) if (c != null) c]
      ],
      opponentIndex: playerManager.opponentIndex,
      actions: List<ActionEntry>.from(actionSync.analyzerActions),
      stackSizes: Map<int, int>.from(stackService.initialStacks),
      remainingStacks: {
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          i: stackService.getStackForPlayer(i)
      },
      playerPositions: Map<int, String>.from(playerManager.playerPositions),
      playerTypes: Map<int, PlayerType>.from(playerManager.playerTypes),
      comment: handContext.comment,
      tags: handContext.tags,
      commentCursor: handContext.commentCursor,
      tagsCursor: handContext.tagsCursor,
      collapsedHistoryStreets: actionHistory.collapsedStreets(),
      foldedPlayers: foldedPlayers.toNullableList(),
      actionTags: actionTagService.toNullableMap(),
      effectiveStacksPerStreet: potSync.toNullableJson(),
      showFullBoard: reveal['showFullBoard'] as bool,
      revealStreet: reveal['revealStreet'] as int,
    );
    return playbackManager.applyTo(hand);
  }

  void recordSnapshot() {
    _undoStack.add(_currentSnapshot());
    _redoStack.clear();
  }

  void resetHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void _applySnapshot(SavedHand snap) {
    lockService.lock();
    try {
      handContext.restore(
        name: snap.name,
        comment: snap.comment,
        commentCursor: snap.commentCursor,
        tags: snap.tags,
        tagsCursor: snap.tagsCursor,
      );
      playerManager.restoreFromHand(snap);
      boardManager.setBoardCards(snap.boardCards);
      playbackManager.stackService.reset(
        Map<int, int>.from(snap.stackSizes),
        remainingStacks: snap.remainingStacks,
      );
      actionSync.setAnalyzerActions(List<ActionEntry>.from(snap.actions));
      potSync.restoreFromHand(snap);
      actionTagService.restoreFromHand(snap);
      foldedPlayers.restoreFromHand(snap);
      actionHistory.restoreFromCollapsed(snap.collapsedHistoryStreets);
      actionHistory.updateHistory(actionSync.analyzerActions,
          visibleCount: playbackManager.playbackIndex);
      boardManager.boardStreet = snap.boardStreet;
      boardManager.currentStreet = snap.boardStreet;
      boardReveal.restoreFromHand(snap);
      playbackManager.restoreFromHand(snap);
      boardManager.startBoardTransition();
    } finally {
      lockService.unlock();
    }
  }

  void undo() {
    if (lockService.undoRedoTransitionLock || lockService.isLocked) return;
    if (_undoStack.isEmpty) return;
    final snap = _undoStack.removeLast();
    _redoStack.add(_currentSnapshot());
    _applySnapshot(snap);
  }

  void redo() {
    if (lockService.undoRedoTransitionLock || lockService.isLocked) return;
    if (_redoStack.isEmpty) return;
    final snap = _redoStack.removeLast();
    _undoStack.add(_currentSnapshot());
    _applySnapshot(snap);
  }
}
