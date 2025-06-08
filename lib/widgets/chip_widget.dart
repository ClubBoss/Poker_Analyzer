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
    final double size = 30 * scale;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black38,
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 2)],
      ),
      child: Text(
        '\$${amount}',
        style: TextStyle(color: Colors.white, fontSize: 12 * scale),
        textAlign: TextAlign.center,
      ),
    );
  }
}
