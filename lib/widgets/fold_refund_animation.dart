import 'package:flutter/material.dart';
import 'chip_stack_widget.dart';
import 'refund_chip_stack_moving_widget.dart';

/// Animation of chips refunded after a fold flying from the pot
/// back to the player's stack with a subtle fade-in.
class FoldRefundAnimation extends StatefulWidget {
  /// Global start position (usually the center of the table).
  final Offset start;

  /// Global end position of the folding player.
  final Offset end;

  /// Amount of chips to animate.
  final int amount;

  /// Scale factor applied to the widget.
  final double scale;

  /// Optional control point for the bezier path.
  final Offset? control;

  /// Called when the animation completes.
  final VoidCallback? onCompleted;

  /// Color of the refunded chips.
  final Color color;

  const FoldRefundAnimation({
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
  State<FoldRefundAnimation> createState() => _FoldRefundAnimationState();
}

class _FoldRefundAnimationState extends State<FoldRefundAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
    ]).animate(_controller);
    _scaleAnim = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
        final control =
            widget.control ??
            Offset(
              (widget.start.dx + widget.end.dx) / 2,
              (widget.start.dy + widget.end.dy) / 2 -
                  (40 + RefundChipStackMovingWidget.activeCount * 8) *
                      widget.scale,
            );
        final pos = _bezier(
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
      child: ChipStackWidget(
        amount: widget.amount,
        scale: 0.8 * widget.scale,
        color: widget.color,
      ),
    );
  }
}
