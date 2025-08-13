import 'dart:math';
import 'package:flutter/material.dart';
import '../../helpers/table_geometry_helper.dart';
import '../../helpers/action_formatting_helper.dart';
import '../../models/action_entry.dart';
import '../bet_chips_on_table.dart';
import '../player_bet_indicator.dart';
import '../chip_stack_widget.dart';
import '../chip_amount_widget.dart';
import '../central_pot_widget.dart';
import '../central_spr_widget.dart';

class BetDisplayInfo {
  final int amount;
  final Color color;
  final String id;

  BetDisplayInfo(this.amount, this.color) : id = UniqueKey().toString();
}

class StackDisplay extends StatelessWidget {
  final double scale;
  final int numberOfPlayers;
  final int currentStreet;
  final int viewIndex;
  final List<ActionEntry> actions;
  final List<int> pots;
  final List<int> sidePots;
  final PlaybackManagerService playbackManager;
  final ActionEntry? centerChipAction;
  final bool showCenterChip;
  final Offset? centerChipOrigin;
  final Animation<double> centerChipController;
  final Animation<double> potGrowth;
  final Animation<int> potCount;
  final Color Function(String) actionColor;
  final Map<int, BetDisplayInfo> centerBets;
  final int currentPot;
  final double? sprValue;

  const StackDisplay({
    super.key,
    required this.scale,
    required this.numberOfPlayers,
    required this.currentStreet,
    required this.viewIndex,
    required this.actions,
    required this.pots,
    required this.sidePots,
    required this.playbackManager,
    required this.centerChipAction,
    required this.showCenterChip,
    required this.centerChipOrigin,
    required this.centerChipController,
    required this.potGrowth,
    required this.potCount,
    required this.centerBets,
    required this.actionColor,
    required this.currentPot,
    required this.sprValue,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 -
        TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final List<Widget> items = [];

    final pot = currentPot;
    if (pot > 0) {
      items.add(
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: const Alignment(0, -0.05),
              child: Transform.translate(
                offset: Offset(0, -12 * scale),
                child: CentralPotWidget(
                  text: 'Main Pot: ${ActionFormattingHelper.formatAmount(pot)}',
                  scale: scale,
                ),
              ),
            ),
          ),
        ),
      );

      if (sprValue != null) {
        items.add(
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -0.05),
                child: Transform.translate(
                  offset: Offset(0, 16 * scale),
                  child: CentralSprWidget(
                    text: 'SPR: ${sprValue!.toStringAsFixed(2)}',
                    scale: scale * 0.9,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    for (int i = 0; i < sidePots.length; i++) {
      final offsetY = (-12 + 36 * (i + 1)) * scale;
      final amount = sidePots[i];
      items.add(
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: const Alignment(0, -0.05),
              child: Transform.translate(
                offset: Offset(0, offsetY),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: CentralPotWidget(
                    key: ValueKey('side-$i-$amount'),
                    text:
                        'Side Pot ${i + 1}: ${ActionFormattingHelper.formatAmount(amount)}',
                    scale: scale * 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (centerChipAction != null) {
      items.add(
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: showCenterChip ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedBuilder(
                animation: centerChipController,
                builder: (_, child) {
                  final start = centerChipOrigin ?? Offset(centerX, centerY);
                  final pos = Offset.lerp(start, Offset(centerX, centerY),
                      centerChipController.value)!;
                  return Transform.translate(
                    offset: Offset(pos.dx - centerX, pos.dy - centerY),
                    child: Transform.scale(
                      scale: centerChipController.value,
                      child: Align(
                        alignment: Alignment.center,
                        child: child,
                      ),
                    ),
                  );
                },
                child: ChipAmountWidget(
                  amount: centerChipAction!.amount!.toDouble(),
                  color: actionColor(centerChipAction!.action),
                  scale: scale,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < numberOfPlayers; i++) {
      final index = (i + viewIndex) % numberOfPlayers;
      final playerActions = actions
          .where((a) => a.playerIndex == index && a.street == currentStreet)
          .toList();
      if (playerActions.isEmpty) continue;
      final lastAction = playerActions.last;
      if (['bet', 'raise', 'call', 'all-in'].contains(lastAction.action) &&
          lastAction.amount != null) {
        final angle = 2 * pi * i / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
        final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final end = Offset(centerX, centerY);
        final animate =
            playbackManager.shouldAnimatePlayer(currentStreet, index);
        items.add(
          Positioned.fill(
            child: BetChipsOnTable(
              start: start,
              end: end,
              chipCount: (lastAction.amount! / 20).clamp(1, 5).round(),
              color: actionColor(lastAction.action),
              scale: scale,
              animate: animate,
            ),
          ),
        );
        items.add(
          Positioned(
            left: centerX + dx + 40 * scale,
            top: centerY + dy + bias - 40 * scale,
            child: PlayerBetIndicator(
              action: lastAction.action,
              amount: lastAction.amount!,
              scale: scale,
            ),
          ),
        );
        final stackPos = Offset.lerp(start, end, 0.15)!;
        final stackScale = scale * 0.7;
        items.add(
          Positioned(
            left: stackPos.dx - 6 * stackScale,
            top: stackPos.dy - 12 * stackScale,
            child: ChipStackWidget(
              amount: lastAction.amount!,
              scale: stackScale,
              color: actionColor(lastAction.action),
            ),
          ),
        );
      }
    }

    centerBets.forEach((player, info) {
      final i = (player - viewIndex + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      final end = Offset(centerX, centerY);
      final pos = Offset.lerp(start, end, 0.75)!;
      final chipScale = scale * 0.8;
      items.add(Positioned(
        left: pos.dx - 8 * chipScale,
        top: pos.dy - 8 * chipScale,
        child: BetStackIndicator(
          amount: info.amount,
          color: info.color,
          scale: chipScale,
          duration: const Duration(milliseconds: 1700),
          onComplete: () {},
        ),
      ));
    });

    return Stack(children: items);
  }
}
