import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../poker_analyzer_screen.dart';

class BoardControls extends StatelessWidget {
  const BoardControls({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<PokerAnalyzerScreenState>();
    final scale = TableGeometryHelper.tableScale(s.numberOfPlayers);
    final viewIndex = s._viewIndex();
    final pot = s._potSync.pots[s.currentStreet];
    final effectiveStack =
        s._potSync.calculateEffectiveStack(s.currentStreet, s.actions);
    final double? sprValue = pot > 0 ? effectiveStack / pot : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Stack(
        children: [
          _TableBackgroundSection(scale: scale),
          AbsorbPointer(
            absorbing: s.lockService.isLocked,
            child: BoardEditor(
              key: s._boardKey,
              scale: scale,
              currentStreet: s.currentStreet,
              boardCards: s.boardCards,
              revealedBoardCards: s._boardReveal.revealedBoardCards,
              onCardSelected: s.selectBoardCard,
              onCardLongPress: s._removeBoardCard,
              canEditBoard: (i) => s._boardEditing.canEditBoard(context, i),
              usedCards: s._boardEditing.usedCardKeys(),
              editingDisabled: s.lockService.isLocked,
              potSync: s._potSync,
              boardReveal: s.widget.boardReveal,
              showPot: false,
            ),
          ),
          PlayerZone(
            numberOfPlayers: s.numberOfPlayers,
            scale: scale,
            playerPositions: s.playerPositions,
            opponentCardRow: AbsorbPointer(
              absorbing: s.lockService.isLocked,
              child: _OpponentCardRowSection(
                scale: scale,
                players: s.players,
                activePlayerIndex: s.activePlayerIndex,
                opponentIndex: s.opponentIndex,
                onCardTap:
                    s.lockService.isLocked ? null : s._onOpponentCardTap,
              ),
            ),
            playerBuilder: s._buildPlayerWidgets,
            chipTrailBuilder: s._buildChipTrail,
          ),
          _BetStacksOverlaySection(scale: scale, state: s),
          _ActionBetStackOverlaySection(scale: scale, state: s),
          _InvestedChipsOverlaySection(scale: scale, state: s),
          StackDisplay(
            scale: scale,
            numberOfPlayers: s.numberOfPlayers,
            currentStreet: s.currentStreet,
            viewIndex: viewIndex,
            actions: s.actions,
            pots: s._potSync.pots,
            sidePots: s._sidePots,
            playbackManager: s._playbackManager,
            centerChipAction: s._centerChipAction,
            showCenterChip: s._showCenterChip,
            centerChipOrigin: s._centerChipOrigin,
            centerChipController: s._centerChipController,
            potGrowth: s._potGrowthAnimation,
            potCount: s._potCountAnimation,
            currentPot: s._currentPot,
            sprValue: sprValue,
            centerBets: s._centerBetStacks,
            actionColor: ActionFormattingHelper.actionColor,
          ),
          _ChipFlightOverlay(flights: s._chipFlights, onRemove: s._removeChipFlight),
          _ActionHistorySection(
            actionHistory: s._actionHistory,
            playerPositions: s.playerPositions,
            expandedStreets: s._expandedHistoryStreets,
            onToggleStreet: (i) {
              s.lockService.safeSetState(s, () {
                s._actionHistory.toggleStreet(i);
              });
            },
            onEdit: s._editAction,
            onDelete: s._deleteAction,
            onReorder: s._reorderAction,
            isLocked: s.lockService.isLocked,
          ),
          _PerspectiveSwitchButton(
            isPerspectiveSwitched: s.isPerspectiveSwitched,
            onToggle: () =>
                s.lockService.safeSetState(s, () => s.isPerspectiveSwitched = !s.isPerspectiveSwitched),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: s._demoAnimations.narration,
            builder: (_, demoText, __) {
              final text = demoText ?? s._playbackNarration;
              return _PlaybackNarrationOverlay(text: text);
            },
          ),
          StreetIndicator(street: s.currentStreet),
          _HudOverlaySection(
            streetName: ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][s.currentStreet],
            potText: ActionFormattingHelper.formatAmount(pot),
            stackText: ActionFormattingHelper.formatAmount(effectiveStack),
            sprText: sprValue != null ? 'SPR: ${sprValue.toStringAsFixed(1)}' : null,
          ),
          if (s.lockService.isLocked) const _BoardTransitionBusyIndicator(),
          _RevealAllCardsButton(
            showAllRevealedCards: s._debugPrefs.showAllRevealedCards,
            onToggle: () async {
              await s._debugPrefs.setShowAllRevealedCards(!s._debugPrefs.showAllRevealedCards);
              s.lockService.safeSetState(s, () {});
            },
          ),
          _FinishHandButtonOverlay(
            onPressed: s._finishHand,
            disabled: s.lockService.isLocked,
            visible: s._showFinishHandButton,
          ),
          if (s.widget.demoMode)
            _ReplayDemoButtonOverlay(onPressed: s._replayDemo, visible: s._showReplayDemoButton),
          _HandCompleteOverlay(visible: s._showHandCompleteIndicator),
          if (s._showNextHandButton)
            _NextHandButtonOverlay(onPressed: s._onNextHandPressed),
          if (s._trainingMode)
            _FoldAllButtonOverlay(onPressed: s._foldAllOpponents),
        ],
      ),
    );
  }
}

