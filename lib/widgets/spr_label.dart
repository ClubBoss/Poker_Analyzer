import 'package:flutter/material.dart';

/// Displays the player's stack-to-pot ratio as simple text.
class SPRLabel extends StatelessWidget {
  /// Current SPR value to display.
  final double? spr;

  /// Scale factor for sizing.
  final double scale;

  const SPRLabel({Key? key, required this.spr, this.scale = 1.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (spr == null) return const SizedBox.shrink();
    return Text(
      'SPR: ${spr!.toStringAsFixed(1)}',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12 * scale,
        fontWeight: FontWeight.w600,
        shadows: const [
          Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.blueAccent),
        ],
      ),
    );
  }
}
