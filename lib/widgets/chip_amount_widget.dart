import 'package:flutter/material.dart';

/// Displays a small chip-like label with amount in big blinds.
class ChipAmountWidget extends StatelessWidget {
  /// Amount in big blinds.
  final double amount;

  /// Background color of the chip label.
  final Color color;

  /// Scale factor for size.
  final double scale;

  const ChipAmountWidget({
    Key? key,
    required this.amount,
    required this.color,
    this.scale = 1.0,
  }) : super(key: key);

  String _format(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final text = '${_format(amount)} BB';
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey(text),
        padding:
            EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 12 * scale),
        ),
      ),
    );
  }
}
