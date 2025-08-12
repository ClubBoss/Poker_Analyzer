import 'package:flutter/material.dart';

/// Visual representation of a stack of poker chips.
class ChipWidget extends StatelessWidget {
  /// Amount of chips represented by this widget.
  final int amount;

  /// Scale factor for sizing.
  final double scale;

  /// Creates a [ChipWidget].
  const ChipWidget({super.key, required this.amount, this.scale = 1.0});

  Color _chipColor() {
    if (amount >= 1000) return Colors.redAccent;
    if (amount >= 500) return Colors.blueAccent;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();

    final int chipCount = (amount / 100).clamp(1, 6).round();
    final double size = 10 * scale;
    final color = _chipColor();

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
                  alignment:
                      i == chipCount - 1 ? Alignment.center : Alignment.bottomCenter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 3 * scale,
                        offset: const Offset(1, 2),
                      )
                    ],
                  ),
                  child: i == chipCount - 1
                      ? Text(
                          '\$$amount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
