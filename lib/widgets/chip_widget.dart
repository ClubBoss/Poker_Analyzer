import 'package:flutter/material.dart';

class ChipWidget extends StatelessWidget {
  final int amount;
  final String chipType; // "bet" or "stack"
  final double scale;

  const ChipWidget({
    Key? key,
    required this.amount,
    this.chipType = 'stack',
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isBet = chipType == 'bet';
    final gradientColors = isBet
        ? const [Color(0xFFB22222), Colors.black]
        : const [Color(0xFF4A4A4A), Colors.black];
    final shadow = BoxShadow(
      color: Colors.black.withOpacity(isBet ? 0.6 : 0.3),
      blurRadius: isBet ? 6 : 4,
      offset: const Offset(0, 2),
    );

    return Container(
      width: 40 * scale,
      height: 40 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.black87, width: 1),
        boxShadow: [shadow],
      ),
      child: Text(
        '\$${amount}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
