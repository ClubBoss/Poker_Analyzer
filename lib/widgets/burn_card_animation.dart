import 'package:flutter/material.dart';

/// Animation of a burn card flying to the discard pile and fading out.
class BurnCardAnimation extends StatefulWidget {
  /// Start position of the card (typically deck center).
  final Offset start;

  /// End position where the card fades out.
  final Offset end;

  /// Scale factor for card size.
  final double scale;

  /// Duration of the animation.
  final Duration duration;

  /// Callback when animation completes.
  final VoidCallback? onCompleted;

  const BurnCardAnimation({
    Key? key,
    required this.start,
    required this.end,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 300),
    this.onCompleted,
  }) : super(key: key);

  @override
  State<BurnCardAnimation> createState() => _BurnCardAnimationState();
}

class _BurnCardAnimationState extends State<BurnCardAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  late final Animation<double> _opacity;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onCompleted?.call();
        }
      });
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );
    _rotation = Tween<double>(begin: 0.0, end: 0.5).animate(_progress);
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
    final width = 36 * widget.scale;
    final height = 52 * widget.scale;
    final control = Offset.lerp(widget.start, widget.end, 0.3)! -
        Offset(0, 40 * widget.scale);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = _bezier(widget.start, control, widget.end, _progress.value);
        return Positioned(
          left: pos.dx - width / 2,
          top: pos.dy - height / 2,
          child: FadeTransition(
            opacity: _opacity,
            child: Transform.rotate(angle: _rotation.value, child: child),
          ),
        );
      },
      child: Image.asset(
        'assets/cards/card_back.png',
        width: width,
        height: height,
      ),
    );
  }
}
