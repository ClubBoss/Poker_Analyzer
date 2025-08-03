import 'package:flutter/material.dart';

/// Displays the current bet as a circular chip.
class BetChip extends StatelessWidget {
  final int currentBet;
  final double scale;
  final TextStyle style;

  const BetChip({
    Key? key,
    required this.currentBet,
    required this.scale,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double radius = 12 * scale;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: currentBet > 0
          ? Container(
              key: ValueKey(currentBet),
              width: radius * 2,
              height: radius * 2,
              margin: EdgeInsets.symmetric(horizontal: 4 * scale),
              decoration: BoxDecoration(
                color: Colors.yellowAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 3 * scale,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$currentBet',
                style: style.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : SizedBox(width: radius * 2, height: radius * 2),
    );
  }
}

