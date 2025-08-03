import 'package:flutter/material.dart';
import '../chip_stack_moving_widget.dart';

/// Widget animating a player's bet flying from their position to the pot.
class BetFlyingChips extends StatelessWidget {
  final Offset start;
  final Offset end;
  final int amount;
  final Color color;
  final double scale;
  final Offset? control;
  final VoidCallback? onCompleted;
  final double fadeStart;
  final TextStyle? labelStyle;

  const BetFlyingChips({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    required this.color,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
    this.fadeStart = 0.0,
    this.labelStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChipStackMovingWidget(
      start: start,
      end: end,
      control: control,
      amount: amount,
      color: color,
      scale: scale,
      onCompleted: onCompleted,
      fadeStart: fadeStart,
      labelStyle: labelStyle,
      showLabel: true,
    );
  }
}
