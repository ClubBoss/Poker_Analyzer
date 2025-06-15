import 'package:flutter/material.dart';

import '../models/saved_hand.dart';
import '../models/player_model.dart';
import '../models/action_evaluation_request.dart';
import 'action_sync_service.dart';
import 'player_manager_service.dart';
import 'playback_manager_service.dart';
import 'evaluation_queue_service.dart';
import 'stack_manager_service.dart';
import 'transition_lock_service.dart';

class HandRestoreService {
  HandRestoreService({
    required this.lockService,
    required this.playerManager,
    required this.actionSync,
    required this.playbackManager,
    required this.queueService,
    required this.commentController,
    required this.tagsController,
    required this.actionTags,
    required this.foldedPlayers,
    required this.setStackService,
    required this.setCurrentHandName,
    required this.setActivePlayerIndex,
    required this.autoCollapseStreets,
    required this.ensureBoardStreetConsistent,
    required this.updateRevealedBoardCards,
    required this.recomputeFoldedPlayers,
    required this.startBoardTransition,
  });

  final TransitionLockService lockService;
  final PlayerManagerService playerManager;
  final ActionSyncService actionSync;
  final PlaybackManagerService playbackManager;
  final EvaluationQueueService queueService;
  final TextEditingController commentController;
  final TextEditingController tagsController;
  final Map<int, String?> actionTags;
  final Set<int> foldedPlayers;
  final void Function(StackManagerService) setStackService;
  final void Function(String?) setCurrentHandName;
  final void Function(int?) setActivePlayerIndex;
  final VoidCallback autoCollapseStreets;
  final VoidCallback ensureBoardStreetConsistent;
  final VoidCallback updateRevealedBoardCards;
  final VoidCallback recomputeFoldedPlayers;
  final VoidCallback startBoardTransition;

  void restoreHand(State state, SavedHand hand) {
    lockService.safeSetState(state, () {
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
      final stack = StackManagerService(
        Map<int, int>.from(playerManager.initialStacks),
        remainingStacks: hand.remainingStacks,
      );
      setStackService(stack);
      playbackManager.stackService = stack;
      playerManager.playerPositions
        ..clear()
        ..addAll(hand.playerPositions);
      playerManager.playerTypes
        ..clear()
        ..addAll(hand.playerTypes ??
            {for (final k in hand.playerPositions.keys) k: PlayerType.unknown});
      commentController.text = hand.comment ?? '';
      tagsController.text = hand.tags.join(', ');
      commentController.selection = TextSelection.collapsed(
          offset: hand.commentCursor != null &&
                  hand.commentCursor! <= commentController.text.length
              ? hand.commentCursor!
              : commentController.text.length);
      tagsController.selection = TextSelection.collapsed(
          offset: hand.tagsCursor != null && hand.tagsCursor! <= tagsController.text.length
              ? hand.tagsCursor!
              : tagsController.text.length);
      actionTags
        ..clear()
        ..addAll(hand.actionTags ?? {});
      queueService.pending
        ..clear()
        ..addAll(hand.pendingEvaluations ?? <ActionEvaluationRequest>[]);
      foldedPlayers
        ..clear()
        ..addAll(hand.foldedPlayers ??
            [for (final a in hand.actions) if (a.action == 'fold') a.playerIndex]);
      actionSync.setExpandedStreets([
        for (int i = 0; i < 4; i++)
          if (hand.collapsedHistoryStreets == null ||
              !hand.collapsedHistoryStreets!.contains(i))
            i
      ]);
      autoCollapseStreets();
      actionSync.setBoardStreet(hand.boardStreet);
      actionSync.changeStreet(hand.boardStreet);
      ensureBoardStreetConsistent();
      updateRevealedBoardCards();
      final seekIndex =
          hand.playbackIndex > hand.actions.length ? hand.actions.length : hand.playbackIndex;
      playbackManager.seek(seekIndex);
      actionSync.updatePlaybackIndex(seekIndex);
      playbackManager.animatedPlayersPerStreet.clear();
      playbackManager.updatePlaybackState();
      playerManager.updatePositions();
      if (hand.foldedPlayers == null) {
        recomputeFoldedPlayers();
      }
    });
    startBoardTransition();
    queueService.persist();
  }
}
