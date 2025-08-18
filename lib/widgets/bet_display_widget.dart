import 'package:flutter/material.dart';
import 'chip_stack_widget.dart';

/// Temporary chip stack with amount label used to visualize a bet.
class BetDisplayWidget extends StatelessWidget {
  /// Amount of chips in the stack.
  final int amount;

  /// Color of the chips.
  final Color color;

  /// Scale factor relative to table size.
  final double scale;

  const BetDisplayWidget({
    Key? key,
    required this.amount,
    required this.color,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChipStackWidget(amount: amount, color: color, scale: scale),
        SizedBox(height: 2 * scale),
        Text(
          '+$amount',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
