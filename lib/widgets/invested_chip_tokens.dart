import 'package:flutter/material.dart';
import 'chip_trail.dart';

/// Displays a short row of mini chips representing the
/// amount invested by a player on the current street.
class InvestedChipTokens extends StatelessWidget {
  final int amount;
  final Color color;
  final double scale;

  const InvestedChipTokens({
    Key? key,
    required this.amount,
    required this.color,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    final chipCount = (amount / 10).clamp(1, 5).round();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Row(
        key: ValueKey(amount),
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          chipCount,
          (index) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 2 * scale),
            child: MiniChip(color: color, size: 12 * scale),
          ),
        ),
      ),
    );
  }
}
