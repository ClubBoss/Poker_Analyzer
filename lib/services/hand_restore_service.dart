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
import 'pot_sync_service.dart';

import 'folded_players_service.dart';
import 'board_manager_service.dart';
import 'board_sync_service.dart';
import 'action_tag_service.dart';

/// Restores a [SavedHand] object by updating all runtime services.
///
/// The service synchronizes stacks, player states, board cards, queued
/// evaluations and playback settings. It keeps restoration logic out of the
/// UI while ensuring the analyzer state can be rebuilt from persisted data.

class HandRestoreService {
  HandRestoreService({
    required this.playerManager,
    required this.profile,
    required this.actionSync,
    required this.playbackManager,
    required this.boardManager,
    required this.boardSync,
    required this.queueService,
    required this.backupManager,
    required this.debugPrefs,
    required this.lockService,
    required this.handContext,
    required this.pendingEvaluations,
    required this.foldedPlayers,
    required this.actionTags,
    required this.setCurrentHandName,
    required this.setActivePlayerIndex,
    required this.potSync,
  }) {
    foldedPlayers.attach(actionSync);
  }

  final PlayerManagerService playerManager;
  final PlayerProfileService profile;
  final ActionSyncService actionSync;
  final PlaybackManagerService playbackManager;
  final BoardManagerService boardManager;
  final BoardSyncService boardSync;
  final EvaluationQueueService queueService;
  final BackupManagerService backupManager;
  final DebugPreferencesService debugPrefs;
  final TransitionLockService lockService;
  final CurrentHandContextService handContext;
  final List<ActionEvaluationRequest> pendingEvaluations;
  final FoldedPlayersService foldedPlayers;
  final ActionTagService actionTags;
  final void Function(String) setCurrentHandName;
  final void Function(int?) setActivePlayerIndex;
  final PotSyncService potSync;


  StackManagerService restoreHand(SavedHand hand) {
    setCurrentHandName(hand.name);
    profile.heroIndex = hand.heroIndex;
    profile.heroPosition = hand.heroPosition;
    profile.numberOfPlayers = hand.numberOfPlayers;
    playerManager.numberOfPlayers = hand.numberOfPlayers;
    for (int i = 0; i < playerManager.playerCards.length; i++) {
      playerManager.playerCards[i]
        ..clear()
        ..addAll(i < hand.playerCards.length ? hand.playerCards[i] : []);
    }
    boardManager.setBoardCards(hand.boardCards);
    for (int i = 0; i < profile.players.length; i++) {
      final list = profile.players[i].revealedCards;
      list.fillRange(0, list.length, null);
      if (i < hand.revealedCards.length) {
        final from = hand.revealedCards[i];
        for (int j = 0; j < list.length && j < from.length; j++) {
          list[j] = from[j];
        }
      }
    }
    profile.opponentIndex = hand.opponentIndex;
    setActivePlayerIndex(hand.activePlayerIndex);
    actionSync.setAnalyzerActions(hand.actions);
    playerManager.initialStacks
      ..clear()
      ..addAll(hand.stackSizes);
    final stackService = StackManagerService(
      Map<int, int>.from(playerManager.initialStacks),
      potSync: potSync,
      remainingStacks: hand.remainingStacks,
    );
    actionSync.attachStackManager(stackService);
    playbackManager.stackService = stackService;
    potSync.stackService = stackService;
    profile.playerPositions
      ..clear()
      ..addAll(hand.playerPositions);
    profile.playerTypes
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
    actionTags.restore(hand.actionTags);
    pendingEvaluations
      ..clear()
      ..addAll(hand.pendingEvaluations ?? []);
    if (hand.foldedPlayers != null) {
      foldedPlayers.restore(hand.foldedPlayers!);
    } else {
      foldedPlayers.recompute(hand.actions);
    }
    actionSync.setExpandedStreets([
      for (int i = 0; i < 4; i++)
        if (hand.collapsedHistoryStreets == null ||
            !hand.collapsedHistoryStreets!.contains(i))
          i
    ]);
    _autoCollapseStreets();
    boardManager.boardStreet = hand.boardStreet;
    boardManager.currentStreet = hand.boardStreet;
    boardSync.updateRevealedBoardCards();
    final seekIndex =
        hand.playbackIndex > hand.actions.length ? hand.actions.length : hand.playbackIndex;
    playbackManager.seek(seekIndex);
    playbackManager.animatedPlayersPerStreet.clear();
    playbackManager.updatePlaybackState();
    profile.updatePositions();
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

  // Board state synchronization handled by [boardManager].
}

