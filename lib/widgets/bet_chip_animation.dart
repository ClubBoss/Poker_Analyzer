import 'package:flutter/material.dart';
import 'chip_widget.dart';

/// Animation of chips flying from a start point to an end point.
class BetChipAnimation extends StatefulWidget {
  /// Global start position of the chip stack.
  final Offset start;

  /// Global end position (usually the center of the table).
  final Offset end;

  /// Amount displayed on the chips.
  final int amount;

  /// Scale factor for sizing.
  final double scale;

  /// Called when the animation completes.
  final VoidCallback? onCompleted;

  const BetChipAnimation({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<BetChipAnimation> createState() => _BetChipAnimationState();
}

class _BetChipAnimationState extends State<BetChipAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 20,
      ),
    ]).animate(_controller);

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
          left: pos.dx,
          top: pos.dy,
          child: FadeTransition(
            opacity: _opacity,
            child: child,
          ),
        );
      },
      child: ChipWidget(amount: widget.amount, scale: widget.scale),
    );
  }
}
