import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/table_geometry_helper.dart';
import '../models/player_model.dart';
import '../widgets/player_zone_widget.dart';
import 'pot_sync_service.dart';
import '../widgets/win_amount_widget.dart';

class ChipFlight {
  final Key key;
  final Offset start;
  final Offset end;
  final int amount;
  final int playerIndex;
  final Color color;
  final double scale;

  ChipFlight({
    required this.key,
    required this.start,
    required this.end,
    required this.amount,
    required this.playerIndex,
    required this.color,
    required this.scale,
  });
}

class PotAnimationService {
  void startPotWinFlights({
    required BuildContext context,
    required Map<int, int> payouts,
    required int numberOfPlayers,
    required int Function() viewIndex,
    required List<PlayerModel> players,
    required List<ChipFlight> flights,
    required VoidCallback registerResetAnimation,
    required Map<int, int> displayedPots,
    required int currentStreet,
    required AnimationController potCountController,
    required void Function(Animation<int>) setPotCountAnimation,
    required List<int> sidePots,
    required PotSyncService potSync,
    required VoidCallback refresh,
    required bool mounted,
    required VoidCallback hideLosingHands,
  }) {
    if (payouts.isEmpty) return;
    final scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    payouts.forEach((player, amount) {
      if (amount <= 0) return;
      final i = (player - viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final start = Offset(centerX, centerY);
      final end = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      flights.add(ChipFlight(
        key: UniqueKey(),
        start: start,
        end: end,
        amount: amount,
        playerIndex: player,
        color: Colors.orangeAccent,
        scale: scale,
      ));
      registerResetAnimation();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      for (final p in payouts.keys) {
        showWinnerHighlight(context, players[p].name);
      }
      final prevPot = displayedPots[currentStreet];
      if (prevPot > 0) {
        setPotCountAnimation(
            IntTween(begin: prevPot, end: 0).animate(potCountController));
        potCountController.forward(from: 0);
        displayedPots[currentStreet] = 0;
      }
      if (sidePots.isNotEmpty) {
        sidePots.clear();
        potSync.sidePots.clear();
        refresh();
      }
      hideLosingHands();
    });
  }

  void startSidePotFlights({
    required BuildContext context,
    required Map<int, int> payouts,
    required int numberOfPlayers,
    required int Function() viewIndex,
    required List<PlayerModel> players,
    required List<ChipFlight> flights,
    required VoidCallback registerResetAnimation,
    required Map<int, int> displayedPots,
    required int currentStreet,
    required AnimationController potCountController,
    required void Function(Animation<int>) setPotCountAnimation,
    required List<int> sidePots,
    required PotSyncService potSync,
    required VoidCallback refresh,
    required bool mounted,
    required VoidCallback hideLosingHands,
  }) {
    if (payouts.isEmpty) return;
    final scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final pots = <int>[
      potSync.pots[currentStreet] - sidePots.fold<int>(0, (p, e) => p + e),
      ...sidePots,
    ];
    final totalPot = pots.fold<int>(0, (p, e) => p + e);
    final totalWin = payouts.values.fold<int>(0, (p, e) => p + e);

    for (int pIndex = 0; pIndex < pots.length; pIndex++) {
      final potAmount = pots[pIndex];
      if (potAmount <= 0) continue;
      final start = Offset(centerX, centerY + (-12 + 36 * pIndex) * scale);
      payouts.forEach((player, value) {
        final amount =
            (potAmount * (value / (totalWin == 0 ? 1 : totalWin))).round();
        if (amount <= 0) return;
        final i = (player - viewIndex() + numberOfPlayers) % numberOfPlayers;
        final angle = 2 * pi * i / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
        final end = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        flights.add(ChipFlight(
          key: UniqueKey(),
          start: start,
          end: end,
          amount: amount,
          playerIndex: player,
          color: Colors.orangeAccent,
          scale: scale,
        ));
        registerResetAnimation();
      });
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      for (final p in payouts.keys) {
        showWinnerHighlight(context, players[p].name);
      }
      final prevPot = displayedPots[currentStreet];
      if (prevPot > 0) {
        setPotCountAnimation(
            IntTween(begin: prevPot, end: 0).animate(potCountController));
        potCountController.forward(from: 0);
        displayedPots[currentStreet] = 0;
      }
      if (sidePots.isNotEmpty) {
        sidePots.clear();
        potSync.sidePots.clear();
        refresh();
      }
      hideLosingHands();
    });
  }

  Future<void> triggerRefundAnimations(Map<int, int> refunds) async {
    for (final entry in refunds.entries) {
      final playerIndex = entry.key;
      final amount = entry.value;
      if (amount <= 0) continue;
      dynamic state;
      for (final s in playerZoneRegistry.values) {
        if (s.widget.playerIndex == playerIndex) {
          state = s;
          break;
        }
      }
      if (state == null) continue;
      final context = state.context as BuildContext;
      final lock = Provider.of<TransitionLockService?>(context, listen: false);
      lock?.lock(const Duration(milliseconds: 800));
      state.showRefundGlow();
      state.showRefundMessage(amount);
      state.playWinChipsAnimation(amount);
      await state.animateStackIncrease(amount);
      lock?.unlock();
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }
}
