import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/saved_hand.dart';
import '../undo_history/diff_engine.dart';
import 'action_sync_service.dart';
import 'board_manager_service.dart';
import 'board_reveal_service.dart';
import 'pot_sync_service.dart';
import 'playback_manager_service.dart';
import 'action_tag_service.dart';
import 'all_in_players_service.dart';
import 'action_history_service.dart';
import 'current_hand_context_service.dart';
import 'folded_players_service.dart';
import 'player_manager_service.dart';
import 'transition_lock_service.dart';
import 'transition_history_service.dart';

/// Manages undo/redo snapshots for the full analyzer state.
class UndoRedoService {
  static const int maxHistory = 100;
  final ActionSyncService actionSync;
  final BoardManagerService boardManager;
  final PlaybackManagerService playbackManager;
  final PlayerManagerService playerManager;
  final CurrentHandContextService handContext;
  final ActionTagService actionTagService;
  final ActionHistoryService actionHistory;
  final FoldedPlayersService foldedPlayers;
  final AllInPlayersService allInPlayers;
  final BoardRevealService boardReveal;
  final PotSyncService potSync;
  final TransitionLockService lockService;
  final TransitionHistoryService transitionHistory;
  final DiffEngine diffEngine;

  UndoRedoService({
    required this.actionSync,
    required this.boardManager,
    required this.playbackManager,
    required this.playerManager,
    required this.handContext,
    required this.actionTagService,
    required this.actionHistory,
    required this.foldedPlayers,
    required this.allInPlayers,
    required this.boardReveal,
    required this.potSync,
    required this.lockService,
    required this.transitionHistory,
    required this.diffEngine,
  });

  late Map<String, dynamic> _lastMap = _currentSnapshot().toJson();
  late SavedHand _lastSnapshot = SavedHand.fromJson(_lastMap);
  final List<StateDiff> _undoDiffs = [];
  final List<StateDiff> _redoDiffs = [];

  SavedHand _currentSnapshot() {
    final stackService = playbackManager.stackService;
    final reveal = boardReveal.toJson();
    potSync.updateEffectiveStacks(
      actionSync.analyzerActions,
      playerManager.numberOfPlayers,
    );
    final hand = SavedHand(
      name: handContext.currentHandName ?? '',
      heroIndex: playerManager.heroIndex,
      heroPosition: playerManager.heroPosition,
      numberOfPlayers: playerManager.numberOfPlayers,
      playerCards: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          List<CardModel>.from(playerManager.playerCards[i]),
      ],
      boardCards: List<CardModel>.from(playerManager.boardCards),
      boardStreet: boardManager.boardStreet,
      revealedCards: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          [
            for (final c in playerManager.players[i].revealedCards)
              if (c != null) c,
          ],
      ],
      opponentIndex: playerManager.opponentIndex,
      actions: List<ActionEntry>.from(actionSync.analyzerActions),
      stackSizes: Map<int, int>.from(stackService.initialStacks),
      remainingStacks: {
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          i: stackService.getStackForPlayer(i),
      },
      playerPositions: Map<int, String>.from(playerManager.playerPositions),
      playerTypes: Map<int, PlayerType>.from(playerManager.playerTypes),
      comment: handContext.comment,
      tags: handContext.tags,
      commentCursor: handContext.commentCursor,
      tagsCursor: handContext.tagsCursor,
      collapsedHistoryStreets: actionHistory.collapsedStreets(),
      foldedPlayers: foldedPlayers.toNullableList(),
      allInPlayers: allInPlayers.toNullableList(),
      actionTags: actionTagService.toNullableMap(),
      effectiveStacksPerStreet: potSync.toNullableJson(),
      showFullBoard: reveal['showFullBoard'] as bool,
      revealStreet: reveal['revealStreet'] as int,
    );
    return playbackManager.applyTo(hand);
  }

  void recordSnapshot() {
    final current = _currentSnapshot();
    final currentMap = current.toJson();
    final diff = diffEngine.compute(_lastMap, currentMap);
    _undoDiffs.add(diff);
    if (_undoDiffs.length > maxHistory) _undoDiffs.removeAt(0);
    _redoDiffs.clear();
    _lastSnapshot = current;
    _lastMap = currentMap;
    transitionHistory.recordSnapshot();
  }

  void resetHistory() {
    _undoDiffs.clear();
    _redoDiffs.clear();
    final snap = _currentSnapshot();
    _lastMap = snap.toJson();
    _lastSnapshot = snap;
    transitionHistory.resetHistory();
  }

  void _applySnapshot(SavedHand snap) {
    handContext.restore(
      name: snap.name,
      comment: snap.comment,
      commentCursor: snap.commentCursor,
      tags: snap.tags,
      tagsCursor: snap.tagsCursor,
      tournamentId: snap.tournamentId,
      buyIn: snap.buyIn,
      totalPrizePool: snap.totalPrizePool,
      numberOfEntrants: snap.numberOfEntrants,
      gameType: snap.gameType,
      category: snap.category,
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
    allInPlayers.restoreFromHand(snap);
    actionHistory.restoreFromCollapsed(snap.collapsedHistoryStreets);
    actionHistory.updateHistory(
      actionSync.analyzerActions,
      visibleCount: playbackManager.playbackIndex,
    );
    boardManager.boardStreet = snap.boardStreet;
    boardManager.currentStreet = snap.boardStreet;
    boardReveal.restoreFromHand(snap);
    playbackManager.restoreFromHand(snap);
  }

  void undo() {
    if (_undoDiffs.isEmpty) return;
    final diff = _undoDiffs.removeLast();
    final map = diffEngine.apply(_lastMap, diff.backward);
    final snap = SavedHand.fromJson(map);
    _redoDiffs.add(diff);
    if (_redoDiffs.length > maxHistory) _redoDiffs.removeAt(0);
    _lastSnapshot = snap;
    _lastMap = map;
    transitionHistory.undo(() => _applySnapshot(snap));
  }

  void redo() {
    if (_redoDiffs.isEmpty) return;
    final diff = _redoDiffs.removeLast();
    final map = diffEngine.apply(_lastMap, diff.forward);
    final snap = SavedHand.fromJson(map);
    _undoDiffs.add(diff);
    if (_undoDiffs.length > maxHistory) _undoDiffs.removeAt(0);
    _lastSnapshot = snap;
    _lastMap = map;
    transitionHistory.redo(() => _applySnapshot(snap));
  }
}
