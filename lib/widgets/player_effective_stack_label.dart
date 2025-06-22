import 'package:flutter/material.dart';

/// Displays the current effective stack in BB for a player.
class PlayerEffectiveStackLabel extends StatelessWidget {
  /// Effective stack size to display.
  final int? stack;

  /// Scale factor for sizing.
  final double scale;

  const PlayerEffectiveStackLabel({
    Key? key,
    required this.stack,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stack == null || stack == 0) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        'Eff: $stack BB',
        key: ValueKey(stack),
        style: TextStyle(
          color: Colors.grey,
          fontSize: 10 * scale,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
