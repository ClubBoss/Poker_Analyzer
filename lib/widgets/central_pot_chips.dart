import 'package:flutter/material.dart';
import 'chip_trail.dart';

/// Visual representation of the central pot using chip icons.
class CentralPotChips extends StatelessWidget {
  /// Total amount currently in the pot.
  final int amount;

  /// Scale factor to adapt to table size.
  final double scale;

  const CentralPotChips({
    Key? key,
    required this.amount,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    final chipCount = (amount / 20).clamp(1, 10).round();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Row(
        key: ValueKey(chipCount),
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          chipCount,
          (index) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 2 * scale),
            child: MiniChip(color: Colors.orangeAccent, size: 16 * scale),
          ),
        ),
      ),
    );
  }
}
