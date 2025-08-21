import 'package:flutter/material.dart';
import 'chip_widget.dart';

/// Visual representation of the central pot using chip icons.
class CentralPotChips extends StatelessWidget {
  /// Total amount currently in the pot.
  final int amount;

  /// Scale factor to adapt to table size.
  final double scale;

  const CentralPotChips({Key? key, required this.amount, this.scale = 1.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    final double chipScale = 1.3 * scale;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey(amount),
        padding: EdgeInsets.all(4 * scale),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: ChipWidget(amount: amount, scale: chipScale),
      ),
    );
  }
}
