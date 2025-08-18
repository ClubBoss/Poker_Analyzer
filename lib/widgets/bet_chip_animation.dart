import 'package:flutter/material.dart';
import 'chip_stack_widget.dart';

/// Animation of a small chip stack flying from a player to the pot.
class BetChipAnimation extends StatelessWidget {
  /// Starting position in global coordinates.
  final Offset start;

  /// Ending position at the pot center.
  final Offset end;

  /// Amount of chips represented by the stack.
  final int amount;

  /// Scale factor for sizing.
  final double scale;

  /// Duration of the flight.
  final Duration duration;

  /// Called when the animation completes.
  final VoidCallback? onCompleted;

  const BetChipAnimation({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 500),
    this.onCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      onEnd: onCompleted,
      builder: (context, value, child) {
        final pos = Offset.lerp(start, end, value)!;
        return Positioned(
          left: pos.dx - 12 * scale,
          top: pos.dy - 12 * scale,
          child: child!,
        );
      },
      child: ChipStackWidget(amount: amount, scale: 0.8 * scale),
    );
  }
}
