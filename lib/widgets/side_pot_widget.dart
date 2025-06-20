import 'package:flutter/material.dart';

/// Displays a labeled side pot amount.
class SidePotWidget extends StatelessWidget {
  /// Index of this side pot (0-based).
  final int index;

  /// Amount contained in the side pot.
  final int amount;

  /// Scale factor for sizing.
  final double scale;

  const SidePotWidget({
    Key? key,
    required this.index,
    required this.amount,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Text(
        'Пот ${index + 1}: $amount',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
