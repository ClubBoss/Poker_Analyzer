import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../poker_analyzer_screen.dart';
import 'playback_controls_widget.dart';
import '../../widgets/playback_progress_bar.dart';
import '../../widgets/street_action_history_panel.dart';
import '../../widgets/action_history_expansion_tile.dart';
import '../../widgets/street_actions_widget.dart';
import '../../widgets/street_action_input_widget.dart';
import '../../widgets/analyzer/action_timeline_panel.dart';
import '../../helpers/table_geometry_helper.dart';
import '../../helpers/action_formatting_helper.dart';
import '../../theme/app_colors.dart';
import '../../services/pot_sync_service.dart';

class ActionControls extends StatelessWidget {
  const ActionControls({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<PokerAnalyzerScreenState>();
    final visibleActions = s.actions.take(s._playbackManager.playbackIndex).toList();
    final savedActions = s.actions;
    return Column(
      children: [
        _TotalPotTracker(
          potSync: s._potSync,
          currentStreet: s.currentStreet,
          sidePots: s._sidePots,
        ),
        AbsorbPointer(
          absorbing: s.lockService.isLocked,
          child: PlaybackProgressBar(
            playbackIndex: s._playbackManager.playbackIndex,
            actionCount: s.actions.length,
            onSeek: (index) {
              s.lockService.safeSetState(s, () {
                s._playbackManager.seek(index);
                s._playbackManager.updatePlaybackState();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: AbsorbPointer(
            absorbing: s.lockService.isLocked,
            child: StreetActionHistoryPanel(
              actions: savedActions,
              pots: s._potSync.pots,
              stackSizes: s._stackService.currentStacks,
              playerPositions: s.playerPositions,
              onEdit: s._editAction,
              onDelete: s._deleteAction,
              onInsert: s._insertAction,
              onDuplicate: s._duplicateAction,
              onReorder: s._reorderAction,
              visibleCount: s._playbackManager.playbackIndex,
              evaluateActionQuality: s._evaluateActionQuality,
            ),
          ),
        ),
        AbsorbPointer(
          absorbing: s.lockService.isLocked,
          child: ActionHistoryExpansionTile(
            actions: visibleActions,
            playerPositions: s.playerPositions,
            pots: s._potSync.pots,
            stackSizes: s._stackService.currentStacks,
            onEdit: s._editAction,
            onDelete: s._deleteAction,
            onInsert: s._insertAction,
            onDuplicate: s._duplicateAction,
            onReorder: s._reorderAction,
            visibleCount: s._playbackManager.playbackIndex,
            evaluateActionQuality: s._evaluateActionQuality,
          ),
        ),
        StreetActionsWidget(
          currentStreet: s.currentStreet,
          canGoPrev: s._boardManager.canReverseStreet(),
          onPrevStreet: s.lockService.isLocked
              ? null
              : () => s.lockService.safeSetState(s, s._reverseStreet),
          onStreetChanged: (index) {
            if (s.lockService.isLocked) return;
            s.lockService.safeSetState(s, () {
              s._changeStreet(index);
              s._undoRedoService.recordSnapshot();
            });
          },
        ),
        AbsorbPointer(
          absorbing: s.lockService.isLocked,
          child: StreetActionInputWidget(
            currentStreet: s.currentStreet,
            numberOfPlayers: s.numberOfPlayers,
            playerPositions: s.playerPositions,
            actionHistory: s._actionHistory,
            onAdd: s.handlePlayerAction,
            onEdit: s._editAction,
            onDelete: s._deleteAction,
          ),
        ),
        ActionTimelinePanel(
          actions: visibleActions,
          playbackIndex: s._playbackManager.playbackIndex,
          onTap: (index) {
            s.lockService.safeSetState(s, () {
              s._playbackManager.seek(index);
              s._playbackManager.updatePlaybackState();
            });
          },
          playerPositions: s.playerPositions,
          focusPlayerIndex: s._focusOnHero ? s.heroIndex : null,
          controller: s._timelineController,
          scale: TableGeometryHelper.tableScale(s.numberOfPlayers),
          locked: s.lockService.isLocked,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: PlaybackControls(
            isPlaying: s._playbackManager.isPlaying,
            playbackIndex: s._playbackManager.playbackIndex,
            actionCount: s.actions.length,
            elapsedTime: s._playbackManager.elapsedTime,
            onPlay: s._play,
            onPause: s._pause,
            onPlayAll: s._playAll,
            onStepBackward: s._stepBackwardPlayback,
            onStepForward: s._stepForwardPlayback,
            onPlaybackReset: s._resetPlayback,
            onSeek: s._seekPlayback,
            onSave: () => s.saveCurrentHand(),
            onLoadLast: s.loadLastSavedHand,
            onLoadByName: () => s.loadHandByName(),
            onExportLast: s.exportLastSavedHand,
            onExportAll: s.exportAllHands,
            onImport: s.importHandFromClipboard,
            onImportAll: s.importAllHandsFromClipboard,
            onReset: s._resetHand,
            onBack: s._cancelHandAnalysis,
            focusOnHero: s._focusOnHero,
            onFocusChanged: (v) =>
                s.lockService.safeSetState(s, () => s._focusOnHero = v),
            backDisabled: s._showdownActive,
            disabled: s._transitionHistory.isLocked,
          ),
        ),
      ],
    );
  }
}

class _TotalPotTracker extends StatelessWidget {
  final PotSyncService potSync;
  final int currentStreet;
  final List<int> sidePots;
  const _TotalPotTracker(
      {required this.potSync, required this.currentStreet, required this.sidePots});
  @override
  Widget build(BuildContext context) {
    final currentPot =
        currentStreet < potSync.pots.length ? potSync.pots[currentStreet] : 0;
    final sideTotal = sidePots.fold<int>(0, (p, e) => p + e);
    final totalPot = currentPot + sideTotal;
    if (totalPot <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        'Total Pot: ${ActionFormattingHelper.formatAmount(totalPot)}',
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

