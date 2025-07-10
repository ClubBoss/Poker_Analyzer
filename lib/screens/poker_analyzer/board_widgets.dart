part of '../poker_analyzer_screen.dart';

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

class _BetStacksOverlaySection extends StatelessWidget {
  final double scale;
  final _PokerAnalyzerScreenState state;
  const _BetStacksOverlaySection({required this.scale, required this.state});
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(state.context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 -
        TableGeometryHelper.centerYOffset(state.numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(state.numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;
    final chips = <Widget>[];
    for (int i = 0; i < state.numberOfPlayers; i++) {
      final index = (i + state._viewIndex()) % state.numberOfPlayers;
      final invested =
          state._stackService.getInvestmentForStreet(index, state.currentStreet);
      if (invested > 0) {
        final angle = 2 * pi * i / state.numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
        final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final pos = Offset.lerp(start, Offset(centerX, centerY), 0.15)!;
        final chipScale = scale * 0.8;
        chips.add(Positioned(
          left: pos.dx - 8 * chipScale,
          top: pos.dy - 8 * chipScale,
          child: BetStackChips(amount: invested, scale: chipScale),
        ));
      }
    }
    return Stack(children: chips);
  }
}

class _ActionBetStackOverlaySection extends StatelessWidget {
  final double scale;
  final _PokerAnalyzerScreenState state;
  const _ActionBetStackOverlaySection({required this.scale, required this.state});
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(state.context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 -
        TableGeometryHelper.centerYOffset(state.numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(state.numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;
    final chips = <Widget>[];
    for (int i = 0; i < state.numberOfPlayers; i++) {
      final index = (i + state._viewIndex()) % state.numberOfPlayers;
      final amount = state._actionBetStacks[index];
      final angle = 2 * pi * i / state.numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      final pos = Offset.lerp(start, Offset(centerX, centerY), 0.15)!;
      final chipScale = scale * 0.8;
      chips.add(Positioned(
        left: pos.dx - 8 * chipScale,
        top: pos.dy - 8 * chipScale,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
          child: amount != null
              ? BetStackChips(key: ValueKey(amount), amount: amount, scale: chipScale)
              : SizedBox(key: const ValueKey('empty'), height: 16 * chipScale),
        ),
      ));
    }
    return Stack(children: chips);
  }
}

class _InvestedChipsOverlaySection extends StatelessWidget {
  final double scale;
  final _PokerAnalyzerScreenState state;
  const _InvestedChipsOverlaySection({required this.scale, required this.state});
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(state.context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 -
        TableGeometryHelper.centerYOffset(state.numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(state.numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;
    final chips = <Widget>[];
    for (int i = 0; i < state.numberOfPlayers; i++) {
      final index = (i + state._viewIndex()) % state.numberOfPlayers;
      final invested =
          state._stackService.getInvestmentForStreet(index, state.currentStreet);
      if (invested > 0) {
        final angle = 2 * pi * i / state.numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
        final playerActions = state.actions
            .where((a) => a.playerIndex == index && a.street == state.currentStreet)
            .toList();
        final lastAction = playerActions.isNotEmpty ? playerActions.last : null;
        final color = ActionFormattingHelper.actionColor(lastAction?.action ?? 'bet');
        final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final end = Offset.lerp(start, Offset(centerX, centerY), 0.2)!;
        final animate = state._playbackManager.shouldAnimatePlayer(state.currentStreet, index);
        chips.add(Positioned.fill(
          child: BetChipsOnTable(
            start: start,
            end: end,
            chipCount: (invested / 20).clamp(1, 5).round(),
            color: color,
            scale: scale,
            animate: animate,
          ),
        ));
      }
    }
    return Stack(children: chips);
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
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black38,
        child: const Center(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
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

class _TotalPotTracker extends StatelessWidget {
  final PotSyncService potSync;
  final int currentStreet;
  final List<int> sidePots;
  const _TotalPotTracker({required this.potSync, required this.currentStreet, required this.sidePots});
  @override
  Widget build(BuildContext context) {
    final currentPot = currentStreet < potSync.pots.length ? potSync.pots[currentStreet] : 0;
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
