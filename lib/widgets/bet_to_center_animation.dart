import 'package:flutter/material.dart';
import 'chip_stack_moving_widget.dart';

/// Animation of a player's bet flying from their seat toward the pot.
class BetToCenterAnimation extends StatelessWidget {
  /// Start position in global coordinates.
  final Offset start;

  /// End position in global coordinates (center of the table).
  final Offset end;

  /// Amount represented by the chip stack.
  final int amount;

  /// Chip color depending on action type.
  final Color color;

  /// Scale factor for sizing.
  final double scale;

  /// Optional bezier control point for the path.
  final Offset? control;

  /// Callback when animation completes.
  final VoidCallback? onCompleted;

  const BetToCenterAnimation({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    required this.color,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChipStackMovingWidget(
      start: start,
      end: end,
      amount: amount,
      color: color,
      scale: scale,
      control: control,
      onCompleted: onCompleted,
    );
  }
}
