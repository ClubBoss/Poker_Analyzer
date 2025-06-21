import 'package:flutter/material.dart';
import 'chip_stack_moving_widget.dart';

/// Animation of chips flying to the center and fading out.
class BurnChipsAnimation extends StatelessWidget {
  /// Global start position of the chips.
  final Offset start;

  /// Global end position, usually table center.
  final Offset end;

  /// Amount of chips to animate.
  final int amount;

  /// Scale factor applied to the widget.
  final double scale;

  /// Optional bezier control point.
  final Offset? control;

  /// Called when the animation completes.
  final VoidCallback? onCompleted;

  /// Chip color, defaults to grey.
  final Color color;

  const BurnChipsAnimation({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
    this.color = Colors.grey,
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
      fadeStart: 0.3,
      endRotation: 0.4,
      onCompleted: onCompleted,
    );
  }
}
