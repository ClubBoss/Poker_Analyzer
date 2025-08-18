import 'package:flutter/material.dart';

/// Displays the player's SPR (stack-to-pot ratio) as a small label.
class PlayerSprLabel extends StatelessWidget {
  /// Current SPR value to display.
  final double? spr;

  /// Scale factor for sizing.
  final double scale;

  const PlayerSprLabel({Key? key, required this.spr, this.scale = 1.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (spr == null) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color backgroundColor = isDark ? Colors.white24 : Colors.black26;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey(spr),
        padding: EdgeInsets.symmetric(
          horizontal: 6 * scale,
          vertical: 2 * scale,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8 * scale),
        ),
        child: Text(
          'SPR: ${spr!.toStringAsFixed(1)}',
          style: TextStyle(
            color: textColor,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
