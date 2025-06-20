import 'package:flutter/material.dart';
import 'chip_stack_moving_widget.dart';

/// Animation of a player's remaining stack flying to the pot on all-in.
class AllInChipsAnimation extends StatelessWidget {
  /// Global start position for the animation.
  final Offset start;

  /// Global end position of the pot.
  final Offset end;

  /// Amount of chips moving.
  final int amount;

  /// Scale factor applied to the widget.
  final double scale;

  /// Optional control point for a curved path.
  final Offset? control;

  /// Callback invoked when the animation completes.
  final VoidCallback? onCompleted;

  /// Fraction of the animation after which fading should start.
  final double fadeStart;

  const AllInChipsAnimation({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
    this.fadeStart = 0.7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChipStackMovingWidget(
      start: start,
      end: end,
      amount: amount,
      color: Colors.redAccent,
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
