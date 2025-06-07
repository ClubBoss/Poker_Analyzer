import 'package:flutter/material.dart';

/// Simple widget to visualize chip stacks.
class ChipWidget extends StatelessWidget {
  /// Amount of chips to display.
  final int amount;

  /// Scale factor for the chip widget.
  final double scale;

  /// Creates a [ChipWidget].
  const ChipWidget({super.key, required this.amount, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 5 * scale),
      decoration: BoxDecoration(
        color: Colors.green.shade700.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '\$${amount}',
        style: TextStyle(color: Colors.white, fontSize: 14 * scale),
      ),
    );
  }
}
