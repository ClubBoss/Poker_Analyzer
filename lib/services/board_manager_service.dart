import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/action_entry.dart';
import '../models/card_model.dart';
import 'action_sync_service.dart';
import 'playback_manager_service.dart';
import 'player_manager_service.dart';
import 'transition_lock_service.dart';

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
  })  : _playerManager = playerManager,
        _actionSync = actionSync,
        _playbackManager = playbackManager {
    _playerManager.addListener(_onPlayerManagerChanged);
    updateRevealedBoardCards();
  }

  final PlayerManagerService _playerManager;
  final ActionSyncService _actionSync;
  final PlaybackManagerService _playbackManager;
  final TransitionLockService lockService;

  static const List<int> _stageCardCounts = [0, 3, 4, 5];
  static const Duration _boardRevealDuration = Duration(milliseconds: 200);
  static const Duration _boardRevealStagger = Duration(milliseconds: 50);

  final List<CardModel> revealedBoardCards = [];
  Timer? _boardTransitionTimer;

  List<CardModel> get boardCards => _playerManager.boardCards;

  int get currentStreet => _actionSync.currentStreet;
  set currentStreet(int v) => _actionSync.changeStreet(v);

  int get boardStreet => _actionSync.boardStreet;
  set boardStreet(int v) => _actionSync.setBoardStreet(v);

  List<ActionEntry> get actions => _actionSync.analyzerActions;

  @override
  void dispose() {
    _playerManager.removeListener(_onPlayerManagerChanged);
    _boardTransitionTimer?.cancel();
    super.dispose();
  }

  int _inferBoardStreet() {
    final count = boardCards.length;
    if (count >= _stageCardCounts[3]) return 3;
    if (count >= _stageCardCounts[2]) return 2;
    if (count >= _stageCardCounts[1]) return 1;
    return 0;
  }

  bool _isBoardStageComplete(int stage) {
    return boardCards.length >= _stageCardCounts[stage];
  }

  void ensureBoardStreetConsistent() {
    final inferred = _inferBoardStreet();
    if (inferred != boardStreet) {
      _actionSync.setBoardStreet(inferred);
      _actionSync.changeStreet(inferred);
      startBoardTransition();
    }
  }

  void updateRevealedBoardCards() {
    final visibleCount = _stageCardCounts[currentStreet];
    revealedBoardCards
      ..clear()
      ..addAll(boardCards.take(visibleCount));
  }

  void _onPlayerManagerChanged() {
    final prevStreet = boardStreet;
    ensureBoardStreetConsistent();
    if (boardStreet != prevStreet) {
      _playbackManager.updatePlaybackState();
    }
    updateRevealedBoardCards();
    notifyListeners();
  }

  void _jumpPlaybackToStreet(int street) {
    final index =
        actions.lastIndexWhere((a) => a.street <= street) + 1;
    _playbackManager.seek(index);
    _playbackManager.updatePlaybackState();
  }

  void changeStreet(int street) {
    if (lockService.boardTransitioning) return;
    cancelBoardReveal();
    street = street.clamp(0, boardStreet);
    if (street == currentStreet) return;
    _actionSync.changeStreet(street);
    startBoardTransition();
    _playbackManager.animatedPlayersPerStreet
        .putIfAbsent(street, () => <int>{});
    updateRevealedBoardCards();
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
    if (lockService.boardTransitioning || !canAdvanceStreet()) return;
    changeStreet(currentStreet + 1);
  }

  void reverseStreet() {
    if (lockService.boardTransitioning || !canReverseStreet()) return;
    changeStreet(currentStreet - 1);
  }

  void startBoardTransition() {
    _boardTransitionTimer?.cancel();
    final targetVisible = _stageCardCounts[currentStreet];
    final revealCount = max(0, targetVisible - revealedBoardCards.length);
    final duration = Duration(
      milliseconds: _boardRevealDuration.inMilliseconds +
          _boardRevealStagger.inMilliseconds * (revealCount > 1 ? revealCount - 1 : 0),
    );
    lockService.boardTransitioning = true;
    lockService.undoRedoTransitionLock = true;
    _boardTransitionTimer = Timer(duration, () {
      lockService.boardTransitioning = false;
      lockService.undoRedoTransitionLock = false;
      notifyListeners();
    });
  }

  void cancelBoardReveal() {
    if (lockService.boardTransitioning) {
      _boardTransitionTimer?.cancel();
      lockService.boardTransitioning = false;
      lockService.undoRedoTransitionLock = false;
    }
  }
}
