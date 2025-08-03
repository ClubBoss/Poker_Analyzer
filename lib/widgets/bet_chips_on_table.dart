import 'dart:math';
import 'package:flutter/material.dart';
import 'chip_trail.dart';
import '../constants/app_constants.dart';

/// Displays a small row of chips on the table along the betting trail.
class BetChipsOnTable extends StatelessWidget {
  /// Starting point of the trail (from player).
  final Offset start;

  /// Ending point of the trail (towards the pot).
  final Offset end;

  /// Number of chips to show.
  final int chipCount;

  /// Color of the chips.
  final Color color;

  /// Scale factor to adapt to table scaling.
  final double scale;

  /// Whether to animate the chip appearance.
  final bool animate;

  const BetChipsOnTable({
    Key? key,
    required this.start,
    required this.end,
    required this.chipCount,
    required this.color,
    this.scale = 1.0,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (chipCount <= 0) return const SizedBox.shrink();

    final mid = Offset.lerp(start, end, 0.5)!;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = atan2(dy, dx);
    final len = sqrt(dx * dx + dy * dy);
    final perp = len == 0 ? Offset.zero : Offset(dy / len, -dx / len);
    final pos = mid + perp * 14 * scale;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: pos.dx - chipCount * 7 * scale,
            top: pos.dy - 7 * scale,
            child: Transform.rotate(
              angle: angle,
              child: AnimatedSwitcher(
                duration: animate
                    ? AppConstants.fadeDuration
                    : Duration.zero,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Row(
                  key: ValueKey(chipCount),
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    chipCount,
                    (index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1 * scale),
                      child: MiniChip(color: color, size: 14 * scale),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
