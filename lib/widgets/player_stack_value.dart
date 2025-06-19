import 'package:flutter/material.dart';

/// Displays the current remaining stack with a chip icon.
class PlayerStackValue extends StatelessWidget {
  /// Amount of chips remaining for the player.
  final int stack;

  /// Scale factor controlling the size.
  final double scale;

  const PlayerStackValue({
    Key? key,
    required this.stack,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stack <= 0) return const SizedBox.shrink();
    final iconSize = 12.0 * scale;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * scale,
        vertical: 2 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.casino, size: iconSize, color: Colors.orangeAccent),
          SizedBox(width: 4 * scale),
          Text(
            '$stack',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
