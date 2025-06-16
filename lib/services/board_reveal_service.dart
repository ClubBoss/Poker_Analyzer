import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/card_model.dart';
import 'board_sync_service.dart';
import 'transition_lock_service.dart';

/// Handles board reveal sequencing and transition locking.
class BoardRevealService extends ChangeNotifier {
  BoardRevealService({required this.boardSync, required this.lockService});

  final BoardSyncService boardSync;
  final TransitionLockService lockService;

  /// Duration for individual board card animations.
  static const Duration revealDuration = Duration(milliseconds: 200);

  /// Delay between sequential board reveals.
  static const Duration stagger = Duration(milliseconds: 50);

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  List<CardModel> _prevCards = [];
  int _sequenceId = 0;
  Timer? _transitionTimer;

  List<Animation<double>> get animations => _animations;

  /// Initialize animation controllers using [vsync].
  void init(TickerProvider vsync) {
    _controllers =
        List.generate(5, (_) => AnimationController(vsync: vsync, duration: revealDuration));
    _animations =
        _controllers.map((c) => CurvedAnimation(parent: c, curve: Curves.easeIn)).toList();
    _prevCards = List<CardModel>.from(boardSync.revealedBoardCards);
    for (int i = 0; i < _prevCards.length; i++) {
      _controllers[i].value = 1;
    }
  }

  /// Update reveal animations based on the current street.
  void updateAnimations(int currentStreet) {
    final oldCards = _prevCards;
    final newCards = boardSync.revealedBoardCards;
    final visible = BoardSyncService.stageCardCounts[currentStreet];
    final List<int> toAnimate = [];
    _sequenceId++;
    final currentSeq = _sequenceId;
    for (int i = 0; i < 5; i++) {
      final oldCard = i < oldCards.length ? oldCards[i] : null;
      final newCard = i < newCards.length ? newCards[i] : null;
      final shouldShow = i < visible && newCard != null;
      if (shouldShow && oldCard == null) {
        _controllers[i].value = 0;
        toAnimate.add(i);
      } else if (!shouldShow) {
        _controllers[i].value = 0;
      } else if (oldCard != null && newCard != null &&
          (oldCard.rank != newCard.rank || oldCard.suit != newCard.suit)) {
        _controllers[i].value = 0;
        toAnimate.add(i);
      } else if (shouldShow) {
        _controllers[i].value = 1;
      }
    }
    for (int j = 0; j < toAnimate.length; j++) {
      final index = toAnimate[j];
      Future.delayed(stagger * j, () {
        if (currentSeq != _sequenceId) return;
        _controllers[index].forward(from: 0);
      });
    }
    _prevCards = List<CardModel>.from(newCards);
  }

  void cancelPendingReveals() {
    _sequenceId++;
    for (final c in _controllers) {
      c.stop();
      c.value = 1;
    }
    _prevCards = List<CardModel>.from(boardSync.revealedBoardCards);
  }

  void startBoardTransition(int currentStreet) {
    _transitionTimer?.cancel();
    final targetVisible = BoardSyncService.stageCardCounts[currentStreet];
    final revealCount = max(0, targetVisible - boardSync.revealedBoardCards.length);
    final duration = Duration(
      milliseconds: revealDuration.inMilliseconds +
          stagger.inMilliseconds * (revealCount > 1 ? revealCount - 1 : 0),
    );
    lockService.boardTransitioning = true;
    lockService.undoRedoTransitionLock = true;
    _transitionTimer = Timer(duration, () {
      lockService.boardTransitioning = false;
      lockService.undoRedoTransitionLock = false;
      notifyListeners();
    });
  }

  void cancelBoardReveal() {
    if (lockService.boardTransitioning) {
      _transitionTimer?.cancel();
      lockService.boardTransitioning = false;
      lockService.undoRedoTransitionLock = false;
    }
    cancelPendingReveals();
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
}
