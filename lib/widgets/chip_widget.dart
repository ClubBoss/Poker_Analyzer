import 'package:flutter/material.dart';

/// Simple widget to visualize chip stacks.
class ChipWidget extends StatelessWidget {
  /// Amount of chips to display.
  final int amount;

  /// Creates a [ChipWidget].
  const ChipWidget({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.shade700.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '\$${amount}',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
