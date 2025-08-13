import 'package:flutter/material.dart';
import 'chip_stack_widget.dart';

/// Animates a stack of grey chips flying along a curved path and fading out
/// after reaching the destination. Used for fold refund animations.
class RefundChipStackMovingWidget extends StatefulWidget {
  /// Number of animations currently running.
  static int activeCount = 0;

  /// Start position in global coordinates.
  final Offset start;

  /// End position in global coordinates.
  final Offset end;

  /// Amount represented by the chip stack.
  final int amount;

  /// Chip color, defaults to grey.
  final Color color;

  /// Scale factor applied to the widget.
  final double scale;

  /// Optional bezier control point.
  final Offset? control;

  /// Called when the animation completes.
  final VoidCallback? onCompleted;

  /// Duration of the entire animation.
  final Duration duration;

  const RefundChipStackMovingWidget({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    this.color = Colors.grey,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<RefundChipStackMovingWidget> createState() =>
      _RefundChipStackMovingWidgetState();
}

class _RefundChipStackMovingWidgetState
    extends State<RefundChipStackMovingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    RefundChipStackMovingWidget.activeCount++;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
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
    RefundChipStackMovingWidget.activeCount--;
    _controller.dispose();
    super.dispose();
  }

  Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final control = widget.control ??
            Offset(
              (widget.start.dx + widget.end.dx) / 2,
              (widget.start.dy + widget.end.dy) / 2 -
                  (40 + RefundChipStackMovingWidget.activeCount * 8) *
                      widget.scale,
            );
        final pos =
            _bezier(widget.start, control, widget.end, _controller.value);
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
      child: ChipStackWidget(
        amount: widget.amount,
        scale: 0.8 * widget.scale,
        color: widget.color,
      ),
    );
  }
}
