import 'package:flutter/material.dart';
import 'refund_chip_stack_moving_widget.dart';

/// Animation used when undoing actions so that pot chips fly back
/// to the contributing player's stack.
class UndoRefundAnimation extends StatelessWidget {
  final Offset start;
  final Offset end;
  final int amount;
  final double scale;
  final Offset? control;
  final VoidCallback? onCompleted;
  final Color color;

  const UndoRefundAnimation({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
    this.color = Colors.lightGreenAccent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefundChipStackMovingWidget(
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
