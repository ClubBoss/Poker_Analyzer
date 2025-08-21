import 'package:flutter/material.dart';

/// Stack of chips representing a player's bet on the table.
class BetStackChips extends StatelessWidget {
  /// Amount of chips bet by the player.
  final int amount;

  /// Scale factor depending on table size.
  final double scale;

  const BetStackChips({Key? key, required this.amount, this.scale = 1.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    final chipCount = (amount / 10).clamp(1, 10).round();
    final double size = 8 * scale;
    const Color chipColor = Colors.purpleAccent;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: SizedBox(
        key: ValueKey(amount),
        width: size * 2,
        height: size + chipCount * size * 0.35,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            for (int i = 0; i < chipCount; i++)
              Positioned(
                bottom: i * size * 0.35,
                child: Container(
                  width: size * 2,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [chipColor, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 3,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
