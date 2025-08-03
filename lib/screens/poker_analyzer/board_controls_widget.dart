import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../poker_analyzer_screen.dart';
import 'animation_handlers_widget.dart';

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
          BetStacksOverlay(scale: scale, state: s),
          ActionBetStackOverlay(scale: scale, state: s),
          InvestedChipsOverlay(scale: scale, state: s),
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
          ChipFlightOverlay(flights: s._chipFlights, onRemove: s._removeChipFlight),
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

class _TableBackgroundSection extends StatelessWidget {
  final double scale;
  const _TableBackgroundSection({required this.scale});
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9 * scale;
    final tableHeight = tableWidth * 0.55;
    return Center(
      child: CustomPaint(
        size: Size(tableWidth, tableHeight),
        painter: PokerTablePainter(),
      ),
    );
  }
}

class _ActionHistorySection extends StatelessWidget {
  final ActionHistoryService actionHistory;
  final Map<int, String> playerPositions;
  final Set<int> expandedStreets;
  final ValueChanged<int> onToggleStreet;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final void Function(int, int) onReorder;
  final bool isLocked;
  const _ActionHistorySection({
    required this.actionHistory,
    required this.playerPositions,
    required this.expandedStreets,
    required this.onToggleStreet,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
    required this.isLocked,
  });
  @override
  Widget build(BuildContext context) {
    return ActionHistoryOverlay(
      actionHistory: actionHistory,
      playerPositions: playerPositions,
      expandedStreets: expandedStreets,
      onToggleStreet: onToggleStreet,
      onEdit: onEdit,
      onDelete: onDelete,
      onReorder: onReorder,
      isLocked: isLocked,
    );
  }
}

class _HudOverlaySection extends StatelessWidget {
  final String streetName;
  final String potText;
  final String stackText;
  final String? sprText;
  const _HudOverlaySection({
    required this.streetName,
    required this.potText,
    required this.stackText,
    this.sprText,
  });
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: HudOverlay(
        streetName: streetName,
        potText: potText,
        stackText: stackText,
        sprText: sprText,
      ),
    );
  }
}

class _BoardTransitionBusyIndicator extends StatelessWidget {
  const _BoardTransitionBusyIndicator();
  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: ColoredBox(
        color: Colors.black38,
        child: Center(
          child: SizedBox(width: 40, height: 40, child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _PerspectiveSwitchButton extends StatelessWidget {
  final bool isPerspectiveSwitched;
  final VoidCallback onToggle;
  const _PerspectiveSwitchButton({required this.isPerspectiveSwitched, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: TextButton(
        onPressed: onToggle,
        child: const Text('👁 Смотреть от лица', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _RevealAllCardsButton extends StatelessWidget {
  final bool showAllRevealedCards;
  final VoidCallback onToggle;
  const _RevealAllCardsButton({required this.showAllRevealedCards, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ElevatedButton(onPressed: onToggle, child: const Text('Показать все карты')),
      ),
    );
  }
}

class _FinishHandButtonOverlay extends StatelessWidget {
  final VoidCallback onPressed;
  final bool disabled;
  final bool visible;
  const _FinishHandButtonOverlay({required this.onPressed, required this.disabled, required this.visible});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton(onPressed: disabled ? null : onPressed, child: const Text('Завершить раздачу')),
        ),
      ),
    );
  }
}

class _ReplayDemoButtonOverlay extends StatelessWidget {
  final VoidCallback onPressed;
  final bool visible;
  const _ReplayDemoButtonOverlay({required this.onPressed, required this.visible});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              textStyle: const TextStyle(fontSize: 20),
            ),
            child: const Text('Replay Demo'),
          ),
        ),
      ),
    );
  }
}

class _HandCompleteOverlay extends StatelessWidget {
  final bool visible;
  const _HandCompleteOverlay({required this.visible});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                SizedBox(width: 8),
                Text('Раздача завершена', style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextHandButtonOverlay extends StatelessWidget {
  final VoidCallback onPressed;
  const _NextHandButtonOverlay({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: Container(
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(color: Colors.yellowAccent.withOpacity(0.6), blurRadius: 20, spreadRadius: 5),
          ]),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              textStyle: const TextStyle(fontSize: 20),
            ),
            child: const Text('Next Hand'),
          ),
        ),
      ),
    );
  }
}

class _FoldAllButtonOverlay extends StatelessWidget {
  final VoidCallback onPressed;
  const _FoldAllButtonOverlay({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.extended(
        heroTag: 'foldAllFab',
        backgroundColor: Colors.red,
        onPressed: onPressed,
        label: const Text('Fold All'),
      ),
    );
  }
}


