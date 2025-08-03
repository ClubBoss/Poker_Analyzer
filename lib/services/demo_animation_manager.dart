import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../helpers/table_geometry_helper.dart';
import '../widgets/pot_collection_chips.dart' as chips;
import '../widgets/player_zone_widget.dart' as pzw;
import 'package:provider/provider.dart';
import '../widgets/winner_glow_widget.dart';
import '../widgets/chip_stack_moving_widget.dart';

/// Manages demo mode animations such as narration text and
/// winner/pot overlays.
class DemoAnimationManager {
  /// Current narration text for the playback overlay.
  final ValueNotifier<String?> narration = ValueNotifier<String?>(null);

  Timer? _narrationTimer;
  final List<OverlayEntry> _overlayEntries = [];

  /// Show a short narration message at the top of the screen.
  void showNarration(String text) {
    _narrationTimer?.cancel();
    narration.value = text;
    _narrationTimer = Timer(const Duration(seconds: 2), () {
      narration.value = null;
    });
  }

  /// Wrapper around [showNarration] used during demo playback.
  void playNarration(String text) => showNarration(text);

  /// Display an overlay glow around the given winner's zone.
  void showWinnerZoneOverlay(BuildContext context, String playerName) {
    final registry =
        Provider.of<pzw.PlayerZoneRegistry>(context, listen: false);
    pzw.showWinnerZoneOverlay(context, registry, playerName);
  }

  /// Show chips flying from the pot to the winner's stack.
  void showPotCollectionChips({
    required BuildContext context,
    required Offset start,
    required Offset end,
    required int amount,
    double scale = 1.0,
    Offset? control,
    double fadeStart = 0.7,
  }) {
    chips.showPotCollectionChips(
      context: context,
      start: start,
      end: end,
      amount: amount,
      scale: scale,
      control: control,
      fadeStart: fadeStart,
    );
  }

  /// Display a glow effect for each winner around their player zone.
  void showWinnerGlow({
    required BuildContext context,
    required Set<int> winners,
    required int numberOfPlayers,
    required int Function() viewIndex,
  }) {
    final overlay = Overlay.of(context);
    if (winners.isEmpty) return;

    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final ordered = winners.toList();
    for (int n = 0; n < ordered.length; n++) {
      final playerIndex = ordered[n];
      final i = (playerIndex - viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final pos = Offset(
        centerX + dx - 20 * scale,
        centerY + dy + bias - 110 * scale,
      );
      Future.delayed(Duration(milliseconds: 300 * n), () {
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (_) => WinnerGlowWidget(
            position: pos,
            scale: scale,
            onCompleted: () {
              entry.remove();
              _overlayEntries.remove(entry);
            },
          ),
        );
        overlay.insert(entry);
        _overlayEntries.add(entry);
        Future.delayed(const Duration(milliseconds: 1800), () {
          entry.remove();
          _overlayEntries.remove(entry);
        });
      });
    }
  }

  /// Animate chips from the central pot to the winning player's stack.
  void playPotCollection({
    required BuildContext context,
    required int playerIndex,
    required int amount,
    required int numberOfPlayers,
    required int Function() viewIndex,
  }) {
    if (amount <= 0) return;
    final overlay = Overlay.of(context);

    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final i = (playerIndex - viewIndex() + numberOfPlayers) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
    final start = Offset(centerX, centerY);
    final end = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    final perp = Offset(-sin(angle), cos(angle));
    final control = Offset(
      midX + perp.dx * 20 * scale,
      midY - (40 + ChipStackMovingWidget.activeCount * 8) * scale,
    );

    chips.showPotCollectionChips(
      context: context,
      start: start,
      end: end,
      amount: amount,
      scale: scale,
      control: control,
      fadeStart: 0.6,
    );
  }

  /// Remove any active overlays and timers.
  void dispose() {
    _narrationTimer?.cancel();
    for (final e in _overlayEntries) {
      e.remove();
    }
    _overlayEntries.clear();
  }
}
