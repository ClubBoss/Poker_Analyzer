import 'package:flutter/material.dart';
import 'chip_trail.dart';

/// Column of small chip icons representing a bet stack.
class ChipStackWidget extends StatelessWidget {
  /// Amount of chips to visualize.
  final int amount;

  /// Scale factor depending on table size.
  final double scale;

  /// Color of the chips.
  final Color color;

  const ChipStackWidget({
    Key? key,
    required this.amount,
    this.scale = 1.0,
    this.color = Colors.amber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    final chipCount = (amount / 20).clamp(1, 8).round();
    final chipSize = 12 * scale;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Column(
        key: ValueKey(amount),
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          chipCount,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 2 * scale),
            child: MiniChip(color: color, size: chipSize),
          ),
        ),
      ),
    );
  }
}
