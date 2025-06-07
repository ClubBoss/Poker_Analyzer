import 'package:flutter/material.dart';

/// Displays current pot size above the board cards.
class PotOverBoardWidget extends StatelessWidget {
  /// Current pot size in big blinds.
  final double potAmount;

  /// Scale factor to adapt to table size.
  final double scale;

  const PotOverBoardWidget({
    Key? key,
    required this.potAmount,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.05),
          child: Transform.translate(
            offset: Offset(0, -15 * scale),
            child: Opacity(
              opacity: 0.7,
              child: Text(
                'Pot: ${potAmount.toStringAsFixed(1)} BB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * scale,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
