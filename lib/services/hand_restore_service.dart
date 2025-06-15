import 'dart:async';
import 'package:flutter/material.dart';

import '../models/saved_hand.dart';
import '../models/action_evaluation_request.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import 'action_sync_service.dart';
import 'evaluation_queue_service.dart';
import 'player_manager_service.dart';
import 'playback_manager_service.dart';
import 'stack_manager_service.dart';
import 'backup_manager_service.dart';
import 'debug_preferences_service.dart';
import 'transition_lock_service.dart';
import 'current_hand_context_service.dart';
import 'folded_players_service.dart';

class HandRestoreService {
  HandRestoreService({
    required this.playerManager,
    required this.actionSync,
    required this.playbackManager,
    required this.queueService,
    required this.backupManager,
    required this.debugPrefs,
    required this.lockService,
    required this.handContext,
    required this.pendingEvaluations,
    required this.foldedPlayers,
    required this.revealedBoardCards,
    required this.setCurrentHandName,
    required this.setActivePlayerIndex,
  }) {
    foldedPlayers.attach(actionSync);
  }

  final PlayerManagerService playerManager;
  final ActionSyncService actionSync;
  final PlaybackManagerService playbackManager;
  final EvaluationQueueService queueService;
  final BackupManagerService backupManager;
  final DebugPreferencesService debugPrefs;
  final TransitionLockService lockService;
  final CurrentHandContextService handContext;
  final List<ActionEvaluationRequest> pendingEvaluations;
  final FoldedPlayersService foldedPlayers;
  final List<CardModel> revealedBoardCards;
  final void Function(String) setCurrentHandName;
  final void Function(int?) setActivePlayerIndex;

  static const List<int> _stageCardCounts = [0, 3, 4, 5];

  StackManagerService restoreHand(SavedHand hand) {
    setCurrentHandName(hand.name);
    playerManager.heroIndex = hand.heroIndex;
    playerManager.heroPosition = hand.heroPosition;
    playerManager.numberOfPlayers = hand.numberOfPlayers;
    for (int i = 0; i < playerManager.playerCards.length; i++) {
      playerManager.playerCards[i]
        ..clear()
        ..addAll(i < hand.playerCards.length ? hand.playerCards[i] : []);
    }
    playerManager.boardCards
      ..clear()
      ..addAll(hand.boardCards);
    for (int i = 0; i < playerManager.players.length; i++) {
      final list = playerManager.players[i].revealedCards;
      list.fillRange(0, list.length, null);
      if (i < hand.revealedCards.length) {
        final from = hand.revealedCards[i];
        for (int j = 0; j < list.length && j < from.length; j++) {
          list[j] = from[j];
        }
      }
    }
    playerManager.opponentIndex = hand.opponentIndex;
    setActivePlayerIndex(hand.activePlayerIndex);
    actionSync.setAnalyzerActions(hand.actions);
    playerManager.initialStacks
      ..clear()
      ..addAll(hand.stackSizes);
    final stackService = StackManagerService(
      Map<int, int>.from(playerManager.initialStacks),
      remainingStacks: hand.remainingStacks,
    );
    playbackManager.stackService = stackService;
    playerManager.playerPositions
      ..clear()
      ..addAll(hand.playerPositions);
    playerManager.playerTypes
      ..clear()
      ..addAll(hand.playerTypes ??
          {for (final k in hand.playerPositions.keys) k: PlayerType.unknown});
    handContext.commentController.text = hand.comment ?? '';
    handContext.tagsController.text = hand.tags.join(', ');
    handContext.commentController.selection = TextSelection.collapsed(
        offset: hand.commentCursor != null &&
                hand.commentCursor! <= handContext.commentController.text.length
            ? hand.commentCursor!
            : handContext.commentController.text.length);
    handContext.tagsController.selection = TextSelection.collapsed(
        offset: hand.tagsCursor != null && hand.tagsCursor! <= handContext.tagsController.text.length
            ? hand.tagsCursor!
            : handContext.tagsController.text.length);
    handContext.actionTags
      ..clear()
      ..addAll(hand.actionTags ?? {});
    pendingEvaluations
      ..clear()
      ..addAll(hand.pendingEvaluations ?? []);
    if (hand.foldedPlayers != null) {
      foldedPlayers.setFrom(hand.foldedPlayers!);
    } else {
      foldedPlayers.setFrom({
        for (final a in hand.actions)
          if (a.action == 'fold') a.playerIndex
      });
    }
    actionSync.setExpandedStreets([
      for (int i = 0; i < 4; i++)
        if (hand.collapsedHistoryStreets == null ||
            !hand.collapsedHistoryStreets!.contains(i))
          i
    ]);
    _autoCollapseStreets();
    actionSync.setBoardStreet(hand.boardStreet);
    actionSync.changeStreet(hand.boardStreet);
    _ensureBoardStreetConsistent();
    _updateRevealedBoardCards();
    final seekIndex =
        hand.playbackIndex > hand.actions.length ? hand.actions.length : hand.playbackIndex;
    playbackManager.seek(seekIndex);
    actionSync.updatePlaybackIndex(seekIndex);
    playbackManager.animatedPlayersPerStreet.clear();
    playbackManager.updatePlaybackState();
    playerManager.updatePositions();
    // foldedPlayers recomputes automatically when actions change
    queueService.persist();
    backupManager.startAutoBackupTimer();
    unawaited(debugPrefs.setEvaluationQueueResumed(false));
    return stackService;
  }

  void _autoCollapseStreets() {
    for (int i = 0; i < 4; i++) {
      if (!actionSync.analyzerActions.any((a) => a.street == i)) {
        actionSync.removeExpandedStreet(i);
      }
    }
  }

  int _inferBoardStreet() {
    final count = playerManager.boardCards.length;
    if (count >= _stageCardCounts[3]) return 3;
    if (count >= _stageCardCounts[2]) return 2;
    if (count >= _stageCardCounts[1]) return 1;
    return 0;
  }

  void _ensureBoardStreetConsistent() {
    final inferred = _inferBoardStreet();
    if (inferred != actionSync.boardStreet) {
      actionSync.setBoardStreet(inferred);
      actionSync.changeStreet(inferred);
    }
  }

  void _updateRevealedBoardCards() {
    final visible = _stageCardCounts[actionSync.currentStreet];
    revealedBoardCards
      ..clear()
      ..addAll(playerManager.boardCards.take(visible));
  }
}

