import 'package:flutter/material.dart';
import '../models/card_model.dart';

/// Animation for folding revealed cards after showdown.
/// Moves the cards along a curved path while fading out.
class FoldRevealAnimation extends StatefulWidget {
  final Offset start;
  final Offset end;
  final List<CardModel> cards;
  final Offset? control;
  final double scale;
  final Duration duration;
  final double fadeStart;
  final VoidCallback? onCompleted;

  const FoldRevealAnimation({
    Key? key,
    required this.start,
    required this.end,
    required this.cards,
    this.control,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 600),
    this.fadeStart = 0.4,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<FoldRevealAnimation> createState() => _FoldRevealAnimationState();
}

class _FoldRevealAnimationState extends State<FoldRevealAnimation>
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

  Widget _buildCard(CardModel card, double width, double height) {
    final isRed = card.suit == '♥' || card.suit == '♦';
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${card.rank}${card.suit}',
        style: TextStyle(
          color: isRed ? Colors.red : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18 * widget.scale,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = 36 * widget.scale;
    final height = 52 * widget.scale;
    final cardA = widget.cards.isNotEmpty ? widget.cards[0] : CardModel(rank: '?', suit: '?');
    final cardB = widget.cards.length > 1 ? widget.cards[1] : cardA;
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
              child: _buildCard(cardA, width, height),
            ),
            Positioned(
              left: width * 0.4,
              child: Transform.rotate(
                angle: 0.3,
                child: _buildCard(cardB, width, height),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
