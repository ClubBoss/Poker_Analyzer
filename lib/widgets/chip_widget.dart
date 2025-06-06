import 'package:flutter/material.dart';

class ChipWidget extends StatelessWidget {
  final int amount;
  final String chipType; // "bet" or "stack"

  const ChipWidget({Key? key, required this.amount, this.chipType = 'stack'})
      : super(key: key);

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
      width: 40,
      height: 40,
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
