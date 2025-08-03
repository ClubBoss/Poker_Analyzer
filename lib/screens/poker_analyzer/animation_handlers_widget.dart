import 'dart:math';
import 'package:flutter/material.dart';
import '../poker_analyzer_screen.dart';
import '../../helpers/table_geometry_helper.dart';
import '../../helpers/action_formatting_helper.dart';
import '../../widgets/bet_stack_chips.dart';
import '../../widgets/bet_chips_on_table.dart';
import '../../widgets/chip_moving_widget.dart';
import '../../services/pot_animation_service.dart';

class BetStacksOverlay extends StatelessWidget {
  final double scale;
  final PokerAnalyzerScreenState state;
  const BetStacksOverlay({super.key, required this.scale, required this.state});

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

class ActionBetStackOverlay extends StatelessWidget {
  final double scale;
  final PokerAnalyzerScreenState state;
  const ActionBetStackOverlay({super.key, required this.scale, required this.state});

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
          transitionBuilder: (c, a) =>
              FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
          child: amount != null
              ? BetStackChips(key: ValueKey(amount), amount: amount, scale: chipScale)
              : SizedBox(key: const ValueKey('empty'), height: 16 * chipScale),
        ),
      ));
    }
    return Stack(children: chips);
  }
}

class InvestedChipsOverlay extends StatelessWidget {
  final double scale;
  final PokerAnalyzerScreenState state;
  const InvestedChipsOverlay({super.key, required this.scale, required this.state});

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
        final animate =
            state._playbackManager.shouldAnimatePlayer(state.currentStreet, index);
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

class ChipFlightOverlay extends StatelessWidget {
  final List<ChipFlight> flights;
  final ValueChanged<Key> onRemove;

  const ChipFlightOverlay({super.key, required this.flights, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (flights.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        children: [
          for (final f in flights)
            ChipMovingWidget(
              key: f.key,
              start: f.start,
              end: f.end,
              amount: f.amount,
              color: f.color,
              scale: f.scale,
              onCompleted: () => onRemove(f.key),
            ),
        ],
      ),
    );
  }
}
