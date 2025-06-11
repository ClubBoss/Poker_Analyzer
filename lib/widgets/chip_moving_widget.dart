import 'package:flutter/material.dart';

/// A chip that smoothly moves from a start point to an end point.
class ChipMovingWidget extends StatefulWidget {
  /// Global start position of the chip.
  final Offset start;

  /// Global end position of the chip.
  final Offset end;

  /// Amount displayed on the chip.
  final int amount;

  /// Chip color.
  final Color color;

  /// Scale factor for sizing.
  final double scale;

  /// Callback fired when the animation completes.
  final VoidCallback? onCompleted;

  const ChipMovingWidget({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    required this.color,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<ChipMovingWidget> createState() => _ChipMovingWidgetState();
}

class _ChipMovingWidgetState extends State<ChipMovingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = Offset.lerp(widget.start, widget.end, _controller.value)!;
        return Positioned(
          left: pos.dx - 12 * widget.scale,
          top: pos.dy - 12 * widget.scale,
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 24 * widget.scale,
        height: 24 * widget.scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
        child: Text(
          '${widget.amount}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12 * widget.scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
