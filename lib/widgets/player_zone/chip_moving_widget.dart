import 'package:flutter/material.dart';

/// A chip that smoothly moves from a start point to an end point.
class ChipMovingWidget extends StatefulWidget {
  /// Number of ChipMovingWidget instances currently animating.
  static int activeCount = 0;

  /// Global start position of the chip.
  final Offset start;

  /// Global end position of the chip.
  final Offset end;

  /// Amount displayed on the chip.
  final int amount;

  /// Color of the amount text. This also identifies the action type.
  final Color color;

  /// Scale factor for sizing.
  final double scale;

  /// Optional control point for a curved flight path.
  final Offset? control;

  /// Callback fired when the animation completes.
  final VoidCallback? onCompleted;

  const ChipMovingWidget({
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
  State<ChipMovingWidget> createState() => _ChipMovingWidgetState();
}

class _ChipMovingWidgetState extends State<ChipMovingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    ChipMovingWidget.activeCount++;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    ChipMovingWidget.activeCount--;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Offset bezier(Offset p0, Offset p1, Offset p2, double t) {
          final u = 1 - t;
          return Offset(
            u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
            u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
          );
        }

        final control =
            widget.control ??
            Offset(
              (widget.start.dx + widget.end.dx) / 2,
              (widget.start.dy + widget.end.dy) / 2 -
                  (40 + ChipMovingWidget.activeCount * 8) * widget.scale,
            );
        final pos = bezier(
          widget.start,
          control,
          widget.end,
          _controller.value,
        );
        final sizeFactor = _scaleAnim.value * widget.scale;
        return Positioned(
          left: pos.dx - 12 * sizeFactor,
          top: pos.dy - 12 * sizeFactor,
          child: FadeTransition(
            opacity: _opacity,
            child: Transform.scale(scale: sizeFactor, child: child),
          ),
        );
      },
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4 * widget.scale,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Text(
          '${widget.amount}',
          style: TextStyle(
            color: widget.color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
