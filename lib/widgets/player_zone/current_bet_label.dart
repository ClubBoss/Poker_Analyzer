import 'package:flutter/material.dart';

/// Displays the player's current bet as an icon and amount text.
class CurrentBetLabel extends StatelessWidget {
  /// Current bet amount to show.
  final int bet;

  /// Scale factor for sizing.
  final double scale;

  const CurrentBetLabel({Key? key, required this.bet, this.scale = 1.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bet <= 0) return const SizedBox.shrink();
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;
    return Padding(
      padding: EdgeInsets.only(top: 4.0 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🪙', style: TextStyle(fontSize: 12 * scale)),
          SizedBox(width: 4 * scale),
          Text(
            '$bet',
            style: TextStyle(
              color: textColor,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
