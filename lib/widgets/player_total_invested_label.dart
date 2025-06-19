import 'package:flutter/material.dart';

/// Displays the player's total invested chips across all streets.
class PlayerTotalInvestedLabel extends StatelessWidget {
  /// Total chips invested by the player.
  final int? total;

  /// Scale factor for sizing.
  final double scale;

  const PlayerTotalInvestedLabel({
    Key? key,
    required this.total,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (total == null || total! <= 0) return const SizedBox.shrink();
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
        key: ValueKey(total),
        padding: EdgeInsets.symmetric(
          horizontal: 6 * scale,
          vertical: 2 * scale,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8 * scale),
        ),
        child: Text(
          'Инвестировано: $total',
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
