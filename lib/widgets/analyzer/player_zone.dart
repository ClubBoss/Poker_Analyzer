import 'package:flutter/material.dart';

class PlayerZone extends StatelessWidget {
  final int numberOfPlayers;
  final double scale;
  final Map<int, String> playerPositions;
  final Widget opponentCardRow;
  final List<Widget> Function(int, double) playerBuilder;
  final List<Widget> Function(int, double) chipTrailBuilder;

  const PlayerZone({
    super.key,
    required this.numberOfPlayers,
    required this.scale,
    required this.playerPositions,
    required this.opponentCardRow,
    required this.playerBuilder,
    required this.chipTrailBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        opponentCardRow,
        for (int i = 0; i < numberOfPlayers; i++) ...playerBuilder(i, scale),
        for (int i = 0; i < numberOfPlayers; i++) ...chipTrailBuilder(i, scale),
      ],
    );
  }
}
