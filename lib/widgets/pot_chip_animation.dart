import 'package:flutter/material.dart';
import 'chip_stack_moving_widget.dart';

/// Animation of chips flying from a player to the pot stack.
class PotChipAnimation extends StatelessWidget {
  /// Global start position of the animation.
  final Offset start;

  /// Global end position (pot stack).
  final Offset end;

  /// Amount represented by the chips.
  final int amount;

  /// Optional bezier control point.
  final Offset? control;

  /// Scale factor for sizing.
  final double scale;

  /// Callback when the animation completes.
  final VoidCallback? onCompleted;

  const PotChipAnimation({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    this.control,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChipStackMovingWidget(
      start: start,
      end: end,
      amount: amount,
      color: Colors.orangeAccent,
      scale: scale,
      control: control,
      fadeStart: 0.6,
      onCompleted: onCompleted,
    );
  }
}
