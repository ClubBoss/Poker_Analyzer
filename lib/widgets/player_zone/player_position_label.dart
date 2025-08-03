import 'package:flutter/material.dart';

/// Returns a color associated with a poker table position.
Color getPositionColor(String? position) {
  switch (position) {
    case 'BTN':
      return Colors.amber;
    case 'SB':
    case 'BB':
      return Colors.blueAccent;
    default:
      return Colors.white70;
  }
}

/// Displays the player's table position like BTN or UTG.
class PlayerPositionLabel extends StatelessWidget {
  final String? position;
  final double scale;
  final bool isDark;

  const PlayerPositionLabel({
    Key? key,
    required this.position,
    this.scale = 1.0,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (position == null) return const SizedBox.shrink();
    return Text(
      position!,
      style: TextStyle(
        color: getPositionColor(position),
        fontSize: 12 * scale,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }
}
