import 'package:flutter/material.dart';

class FoldFlyingCards extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Offset? control;
  final double scale;
  final Duration duration;
  final double fadeStart;
  final VoidCallback? onCompleted;

  const FoldFlyingCards({
    Key? key,
    required this.start,
    required this.end,
    this.control,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 600),
    this.fadeStart = 0.4,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<FoldFlyingCards> createState() => _FoldFlyingCardsState();
}

class _FoldFlyingCardsState extends State<FoldFlyingCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(widget.fadeStart, 1.0, curve: Curves.easeOut),
      ),
    );
    _rotation = Tween<double>(begin: 0.0, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final control = widget.control ?? Offset(
          (widget.start.dx + widget.end.dx) / 2,
          (widget.start.dy + widget.end.dy) / 2 - 40 * widget.scale,
        );
        final pos = _bezier(widget.start, control, widget.end, _controller.value);
        return Positioned(
          left: pos.dx - (width * 0.7),
          top: pos.dy - height / 2,
          child: FadeTransition(
            opacity: _opacity,
            child: Transform.rotate(
              angle: _rotation.value,
              child: child,
            ),
          ),
        );
      },
      child: SizedBox(
        width: width * 1.4,
        height: height,
        child: Stack(
          children: [
            Transform.rotate(
              angle: -0.3,
              child: Image.asset(
                'assets/cards/card_back.png',
                width: width,
                height: height,
              ),
            ),
            Positioned(
              left: width * 0.4,
              child: Transform.rotate(
                angle: 0.3,
                child: Image.asset(
                  'assets/cards/card_back.png',
                  width: width,
                  height: height,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
