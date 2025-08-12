import 'package:flutter/material.dart';
import 'chip_stack_moving_widget.dart';

/// Animation of chips flying from the pot to a player's stack.
class WinChipsAnimation extends StatelessWidget {
  /// Start position in global coordinates (center pot).
  final Offset start;

  /// End position at the winning player's stack.
  final Offset end;

  /// Chip amount to animate.
  final int amount;

  /// Scale factor applied to the animation.
  final double scale;

  /// Optional control point for the bezier path.
  final Offset? control;

  /// Callback when animation completes.
  final VoidCallback? onCompleted;

  /// Fraction of the animation after which fading should start.
  final double fadeStart;

  /// Color of the chip stack.
  final Color color;

  const WinChipsAnimation({
    super.key,
    required this.start,
    required this.end,
    required this.amount,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
    this.fadeStart = 0.7,
    this.color = const Color(0xFFD8B243),
  });

  @override
  Widget build(BuildContext context) {
    return ChipStackMovingWidget(
      start: start,
      end: end,
      amount: amount,
      color: color,
      scale: scale,
      control: control,
      fadeStart: fadeStart,
      labelStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16 * scale,
        shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
      ),
      showLabel: true,
      onCompleted: onCompleted,
    );
  }
}
