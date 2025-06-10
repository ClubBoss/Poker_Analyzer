import 'package:flutter/material.dart';

/// Simple widget that displays the current pot amount.
///
/// Shows a rounded semi-transparent background with a white label
/// "Pot: X" where `X` is the amount. When the amount changes the
/// label fades between the values.
class PotDisplayWidget extends StatelessWidget {
  /// Amount of chips currently in the pot.
  final int amount;

  /// Scale factor for the text and padding.
  final double scale;

  const PotDisplayWidget({
    Key? key,
    required this.amount,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: amount > 0
          ? Container(
              key: ValueKey(amount),
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 6 * scale,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Text(
                'Pot: $amount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
