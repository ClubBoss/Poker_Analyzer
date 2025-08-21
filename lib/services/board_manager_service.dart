import 'package:flutter/foundation.dart';

import '../models/action_entry.dart';
import '../models/card_model.dart';
import 'action_sync_service.dart';
import 'playback_manager_service.dart';
import 'player_manager_service.dart';
import 'transition_lock_service.dart';
import 'board_sync_service.dart';
import 'board_reveal_service.dart';

/// Manages board state transitions and reveal timing.
///
/// This service centralizes all board-related logic such as the current
/// street, visible board cards and transition locking. It synchronizes board
/// updates with the playback manager and action history to keep the analyzer
/// UI in sync with user edits and playback controls.

class BoardManagerService extends ChangeNotifier {
  BoardManagerService({
    required PlayerManagerService playerManager,
    required ActionSyncService actionSync,
    required PlaybackManagerService playbackManager,
    required this.lockService,
    required BoardSyncService boardSync,
    required this.boardReveal,
  })  : _playerManager = playerManager,
        _actionSync = actionSync,
        _playbackManager = playbackManager,
        _boardSync = boardSync {
    _playerManager.addListener(_onPlayerManagerChanged);
    boardReveal.setRevealStreet(currentStreet);
  }

  final PlayerManagerService _playerManager;
  final ActionSyncService _actionSync;
  final PlaybackManagerService _playbackManager;
  final TransitionLockService lockService;
  final BoardSyncService _boardSync;
  final BoardRevealService boardReveal;

  List<CardModel> get boardCards => _playerManager.boardCards;

  int get currentStreet => _actionSync.currentStreet;
  set currentStreet(int v) => _actionSync.changeStreet(v);

  int get boardStreet => _actionSync.boardStreet;
  set boardStreet(int v) => _actionSync.setBoardStreet(v);

  List<CardModel> get revealedBoardCards => _boardSync.revealedBoardCards;

  List<ActionEntry> get actions => _actionSync.analyzerActions;

  @override
  void dispose() {
    _playerManager.removeListener(_onPlayerManagerChanged);
    super.dispose();
  }

  void _onPlayerManagerChanged() {
    final prevStreet = boardStreet;
    final changed = _boardSync.ensureBoardStreetConsistent();
    _boardSync.updateRevealedBoardCards();
    if (changed) {
      startBoardTransition();
    }
    if (boardStreet != prevStreet) {
      _playbackManager.updatePlaybackState();
    }
    boardReveal.setRevealStreet(currentStreet);
    notifyListeners();
  }

  void _jumpPlaybackToStreet(int street) {
    final index = actions.lastIndexWhere((a) => a.street <= street) + 1;
    _playbackManager.seek(index);
    _playbackManager.updatePlaybackState();
  }

  void changeStreet(int street) {
    if (lockService.isLocked) return;
    cancelBoardReveal();
    street = street.clamp(0, boardStreet);
    if (street == currentStreet) return;
    _actionSync.changeStreet(street);
    _boardSync.updateRevealedBoardCards();
    startBoardTransition();
    _playbackManager.animatedPlayersPerStreet.putIfAbsent(
      street,
      () => <int>{},
    );
    boardReveal.setRevealStreet(currentStreet);
    _jumpPlaybackToStreet(street);
    notifyListeners();
  }

  bool canReverseStreet() {
    if (currentStreet == 0) return false;
    final prev = currentStreet - 1;
    return !actions.any((a) => a.street > prev);
  }

  bool canAdvanceStreet() => currentStreet < boardStreet;

  void advanceStreet() {
    if (lockService.isLocked || !canAdvanceStreet()) return;
    changeStreet(currentStreet + 1);
  }

  void reverseStreet() {
    if (lockService.isLocked || !canReverseStreet()) return;
    changeStreet(currentStreet - 1);
  }

  void startBoardTransition() {
    boardReveal.startBoardTransition(notifyListeners);
  }

  void cancelBoardReveal() {
    if (lockService.boardTransitioning) {
      boardReveal.cancelBoardReveal();
    }
  }

  /// Replace the current board with [cards] and notify listeners.
  void setBoardCards(List<CardModel> cards) {
    _playerManager.boardCards
      ..clear()
      ..addAll(cards);
    _playerManager.notifyListeners();
  }

  /// Clear all community cards and reset board streets.
  void clearBoard() {
    final prevStreet = boardStreet;
    _playerManager.boardCards.clear();
    _playerManager.notifyListeners();
    boardStreet = 0;
    currentStreet = 0;
    _boardSync.updateRevealedBoardCards();
    boardReveal.setRevealStreet(0);
    startBoardTransition();
    if (prevStreet != 0) {
      _playbackManager.updatePlaybackState();
    }
    notifyListeners();
  }

  /// Load board information from a training spot map and reset to preflop.
  void loadFromMap(Map<String, dynamic> data) {
    final boardData = data['boardCards'] as List? ?? [];
    final cards = <CardModel>[];
    for (final c in boardData) {
      if (c is Map) {
        cards.add(
          CardModel(rank: c['rank'] as String, suit: c['suit'] as String),
        );
      }
    }
    setBoardCards(cards);
    changeStreet(0);
  }

  /// Whether [stage] has the required number of board cards.
  bool isBoardStageComplete(int stage) =>
      _boardSync.isBoardStageComplete(stage);
}
