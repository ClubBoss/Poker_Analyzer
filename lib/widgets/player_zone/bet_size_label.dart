import 'package:flutter/material.dart';

/// Glowing chip-style label showing bet amount.
class BetSizeLabel extends StatelessWidget {
  final int amount;
  final Color color;
  final double scale;

  const BetSizeLabel({
    Key? key,
    required this.amount,
    required this.color,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.9);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.8),
            blurRadius: 8 * scale,
            spreadRadius: 1 * scale,
          ),
        ],
      ),
      child: Text(
        '+$amount',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12 * scale,
        ),
      ),
    );
  }
}
