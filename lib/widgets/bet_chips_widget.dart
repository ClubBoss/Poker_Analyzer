import 'package:flutter/material.dart';
import 'chip_stack_widget.dart';

/// Vertical stack of chips representing a player's current bet.
class BetChipsWidget extends StatelessWidget {
  /// Amount of chips bet by the player.
  final int amount;

  /// Color of the chips.
  final Color color;

  /// Scale factor relative to the table size.
  final double scale;

  const BetChipsWidget({
    Key? key,
    required this.amount,
    required this.color,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    return ChipStackWidget(amount: amount, color: color, scale: scale);
  }
}
