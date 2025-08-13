import 'package:flutter/material.dart';
import 'chip_stack_moving_widget.dart';

/// Widget animating chips flying toward the trash with rotation.
class TrashFlyingChips extends StatelessWidget {
  final Offset start;
  final Offset end;
  final int amount;
  final double scale;
  final Offset? control;
  final VoidCallback? onCompleted;
  final double fadeStart;
  final double endRotation;

  const TrashFlyingChips({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
    this.fadeStart = 0.0,
    this.endRotation = -1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChipStackMovingWidget(
      start: start,
      end: end,
      control: control,
      amount: amount,
      color: Colors.grey,
      scale: scale,
      fadeStart: fadeStart,
      endRotation: endRotation,
      onCompleted: onCompleted,
    );
  }
}
