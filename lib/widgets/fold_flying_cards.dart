import 'package:flutter/material.dart';

class FoldFlyingCards extends StatefulWidget {
  /// Index of the folding player.
  final int playerIndex;

  /// Starting positions of the player's two cards.
  final List<Offset> cardPositions;

  /// Scale factor applied to the card images.
  final double scale;

  /// Duration of the full animation.
  final Duration duration;

  /// Fraction of the animation when fading should begin.
  final double fadeStart;

  /// Callback when the animation finishes.
  final VoidCallback? onCompleted;

  const FoldFlyingCards({
    Key? key,
    required this.playerIndex,
    required this.cardPositions,
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
    _rotation = Tween<double>(
      begin: 0.0,
      end: 0.4,
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
    final width = 36 * widget.scale;
    final height = 52 * widget.scale;
    final start = widget.cardPositions.length == 2
        ? Offset(
            (widget.cardPositions[0].dx + widget.cardPositions[1].dx) / 2,
            (widget.cardPositions[0].dy + widget.cardPositions[1].dy) / 2,
          )
        : widget.cardPositions.first;
    final screen = MediaQuery.of(context).size;
    final sign = start.dx > screen.width / 2 ? 1.0 : -1.0;
    final end = start + Offset(sign * 60 * widget.scale, -120 * widget.scale);
    final control =
        start + Offset(sign * 30 * widget.scale, -60 * widget.scale);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = _bezier(start, control, end, _controller.value);
        return Positioned(
          left: pos.dx - (width * 0.7),
          top: pos.dy - height / 2,
          child: FadeTransition(
            opacity: _opacity,
            child: Transform.rotate(angle: _rotation.value, child: child),
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
