import 'dart:async';

import '../models/saved_hand.dart';
import 'action_sync_service.dart';
import 'evaluation_queue_service.dart';
import 'player_manager_service.dart';
import 'playback_manager_service.dart';
import 'stack_manager_service.dart';
import 'debug_panel_preferences.dart';
import 'backup_manager_service.dart';
import 'transition_lock_service.dart';
import 'current_hand_context_service.dart';
import 'pot_sync_service.dart';
import 'action_history_service.dart';

import 'folded_players_service.dart';
import 'all_in_players_service.dart';
import 'board_manager_service.dart';
import 'board_sync_service.dart';
import 'action_tag_service.dart';
import 'board_reveal_service.dart';

/// Restores a [SavedHand] object by updating all runtime services.
///
/// The service synchronizes stacks, player states, board cards, queued
/// evaluations and playback settings. It keeps restoration logic out of the
/// UI while ensuring the analyzer state can be rebuilt from persisted data.

class HandRestoreService {
  HandRestoreService({
    required this.playerManager,
    required this.actionSync,
    required this.playbackManager,
    required this.boardManager,
    required this.boardSync,
    required this.queueService,
    required this.backupManager,
    required this.debugPrefs,
    required this.lockService,
    required this.handContext,
    required this.foldedPlayers,
    required this.actionTags,
    required this.setActivePlayerIndex,
    required this.potSync,
    required this.actionHistory,
    required this.boardReveal,
  }) {
    foldedPlayers.attach(actionSync);
    allInPlayers.attach(actionSync);
  }

  final PlayerManagerService playerManager;
  final ActionSyncService actionSync;
  final PlaybackManagerService playbackManager;
  final BoardManagerService boardManager;
  final BoardSyncService boardSync;
  final EvaluationQueueService queueService;
  final BackupManagerService backupManager;
  final DebugPanelPreferences debugPrefs;
  final TransitionLockService lockService;
  final CurrentHandContextService handContext;
  final FoldedPlayersService foldedPlayers;
  final AllInPlayersService allInPlayers;
  final ActionTagService actionTags;
  final void Function(int?) setActivePlayerIndex;
  final PotSyncService potSync;
  final ActionHistoryService actionHistory;
  final BoardRevealService boardReveal;

  StackManagerService restoreHand(SavedHand hand) {
    lockService.lock();
    try {
      handContext.restoreFromHand(hand);
      playerManager.restoreFromHand(hand);
      boardManager.setBoardCards(hand.boardCards);
      final stackService = StackManagerService(
        Map<int, int>.from(playerManager.initialStacks),
        potSync: potSync,
        remainingStacks: hand.remainingStacks,
      );
      actionSync.attachStackManager(stackService);
      playbackManager.stackService = stackService;
      potSync.stackService = stackService;
      setActivePlayerIndex(hand.activePlayerIndex);
      actionSync.setAnalyzerActions(hand.actions);
      potSync.restoreFromHand(hand);
      actionHistory.updateHistory(
        actionSync.analyzerActions,
        visibleCount: playbackManager.playbackIndex,
      );
      actionTags.restoreFromHand(hand);
      unawaited(queueService.setPending(hand.pendingEvaluations ?? []));
      foldedPlayers.restoreFromHand(hand);
      allInPlayers.restoreFromHand(hand);
      actionHistory.restoreFromCollapsed(hand.collapsedHistoryStreets);
      _autoCollapseStreets();
      actionHistory.updateHistory(
        actionSync.analyzerActions,
        visibleCount: playbackManager.playbackIndex,
      );
      boardManager.boardStreet = hand.boardStreet;
      boardManager.currentStreet = hand.boardStreet;
      boardReveal.restoreFromHand(hand);
      playbackManager.restoreFromHand(hand);
      // foldedPlayers recomputes automatically when actions change
      queueService.persist();
      backupManager.startAutoBackupTimer();
      unawaited(debugPrefs.setEvaluationQueueResumed(false));
      return stackService;
    } finally {
      lockService.unlock();
    }
  }

  void _autoCollapseStreets() {
    for (int i = 0; i < 4; i++) {
      if (!actionSync.analyzerActions.any((a) => a.street == i)) {
        actionHistory.removeStreet(i);
      }
    }
  }

  // Board state synchronization handled by [boardManager].
}
