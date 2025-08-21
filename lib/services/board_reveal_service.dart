import 'dart:math';

import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/saved_hand.dart';
import 'board_sync_service.dart';
import 'transition_lock_service.dart';

/// Manages sequencing and animation of board card reveals.
class BoardRevealService {
  BoardRevealService({required this.lockService, required this.boardSync});

  final TransitionLockService lockService;
  final BoardSyncService boardSync;

  /// Whether all board cards should be shown regardless of the current street.
  bool _showFullBoard = false;

  /// Street currently revealed to the user. Normally matches
  /// [boardSync.currentStreet] unless [_showFullBoard] is true.
  int _revealStreet = 0;

  bool get showFullBoard => _showFullBoard;

  int get revealStreet =>
      _showFullBoard ? boardSync.boardStreet : _revealStreet;

  /// Visible board cards after applying the reveal state.
  List<CardModel> get revealedBoardCards => boardSync.revealedBoardCards;

  static const Duration revealDuration = Duration(milliseconds: 200);
  static const Duration revealStagger = Duration(milliseconds: 50);

  final List<AnimationController> _controllers = [];
  late final List<Animation<double>> animations;
  int _sequenceId = 0;
  int _prevStreet = 0;
  List<CardModel> _prevCards = [];

  void attachTicker(TickerProvider vsync) {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    _controllers.addAll(
      List.generate(
        5,
        (_) => AnimationController(vsync: vsync, duration: revealDuration),
      ),
    );
    animations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeIn))
        .toList();
    _prevStreet = boardSync.currentStreet;
    _revealStreet = boardSync.currentStreet;
    updateRevealState();
    _prevCards = List<CardModel>.from(boardSync.revealedBoardCards);
    for (int i = 0; i < _prevCards.length; i++) {
      _controllers[i].value = 1;
    }
  }

  void dispose() {
    cancelBoardReveal();
    for (final c in _controllers) {
      c.dispose();
    }
  }

  /// Cancel any pending reveal animations and transition timers.
  void cancelBoardReveal() {
    _sequenceId++;
    lockService.cancelBoardTransition();
    for (final c in _controllers) {
      c.stop();
      c.value = 1;
    }
    _prevCards = List<CardModel>.from(boardSync.revealedBoardCards);
  }

  /// Start a board transition and lock actions until animations finish.
  ///
  /// [onComplete] is called when the transition finishes and the lock is
  /// released.
  void startBoardTransition([VoidCallback? onComplete]) {
    final targetVisible =
        BoardSyncService.stageCardCounts[boardSync.currentStreet];
    final revealCount = max(
      0,
      targetVisible - boardSync.revealedBoardCards.length,
    );
    final duration = Duration(
      milliseconds: revealDuration.inMilliseconds +
          revealStagger.inMilliseconds *
              (revealCount > 1 ? revealCount - 1 : 0),
    );
    lockService.startBoardTransition(duration, onComplete);
  }

  /// Update reveal animations based on the current board state.
  void updateAnimations() {
    final visible = BoardSyncService.stageCardCounts[boardSync.currentStreet];
    final List<int> toAnimate = [];
    _sequenceId++;
    final currentSeq = _sequenceId;
    for (int i = 0; i < 5; i++) {
      final oldCard = i < _prevCards.length ? _prevCards[i] : null;
      final newCard = i < boardSync.revealedBoardCards.length
          ? boardSync.revealedBoardCards[i]
          : null;
      final shouldShow = i < visible && newCard != null;
      if (shouldShow && oldCard == null) {
        _controllers[i].value = 0;
        toAnimate.add(i);
      } else if (!shouldShow) {
        _controllers[i].value = 0;
      } else if (oldCard != null &&
          (oldCard.rank != newCard.rank || oldCard.suit != newCard.suit)) {
        _controllers[i].value = 0;
        toAnimate.add(i);
      } else if (shouldShow) {
        _controllers[i].value = 1;
      }
    }
    for (int j = 0; j < toAnimate.length; j++) {
      final index = toAnimate[j];
      Future.delayed(revealStagger * j, () {
        if (currentSeq != _sequenceId) return;
        _controllers[index].forward(from: 0);
      });
    }
    _prevCards = List<CardModel>.from(boardSync.revealedBoardCards);
    _prevStreet = boardSync.currentStreet;
  }

  /// Synchronize [boardSync.revealedBoardCards] with the current reveal state.
  void updateRevealState() {
    boardSync.syncRevealState(
      revealStreet: _revealStreet,
      showFullBoard: _showFullBoard,
    );
  }

  /// Toggle showing the full board regardless of the current street.
  void toggleFullBoard() {
    _showFullBoard = !_showFullBoard;
    updateRevealState();
  }

  /// Reset reveal tracking to the provided [street].
  void setRevealStreet(int street) {
    _revealStreet = street;
    updateRevealState();
  }

  /// Reveal board cards up to [street] and animate newly visible cards.
  void revealStreet(int street) {
    _revealStreet = street;
    updateRevealState();
    updateAnimations();
  }

  /// Returns true if [stage] is currently revealed.
  bool isStageRevealed(int stage) => revealStreet >= stage;

  /// Serializes the current reveal state to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'showFullBoard': _showFullBoard,
        'revealStreet': revealStreet,
      };

  /// Returns a copy of the current reveal state map, or `null` when
  /// using the default values.
  Map<String, dynamic>? toNullableJson() {
    if (!_showFullBoard && revealStreet == boardSync.boardStreet) return null;
    return toJson();
  }

  /// Restores reveal state from [json] produced by [toJson].
  void restoreFromJson(Map<String, dynamic>? json) {
    _showFullBoard = json?['showFullBoard'] as bool? ?? false;
    _revealStreet = (json?['revealStreet'] as int?) ?? boardSync.currentStreet;
    updateRevealState();
  }

  /// Restores board reveal information from [hand].
  void restoreFromHand(SavedHand hand) {
    restoreFromJson({
      'showFullBoard': hand.showFullBoard,
      'revealStreet': hand.revealStreet,
    });
  }
}
