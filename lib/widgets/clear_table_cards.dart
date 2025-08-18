import 'package:flutter/material.dart';
import '../models/card_model.dart';

/// Animation for clearing table cards.
/// Slides the card down off-screen while fading out.
class ClearTableCards extends StatefulWidget {
  final Offset start;
  final CardModel card;
  final double scale;
  final Duration duration;
  final VoidCallback? onCompleted;

  const ClearTableCards({
    Key? key,
    required this.start,
    required this.card,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 600),
    this.onCompleted,
  }) : super(key: key);

  @override
  State<ClearTableCards> createState() => _ClearTableCardsState();
}

class _ClearTableCardsState extends State<ClearTableCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offsetY;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0)),
    );
    _offsetY = Tween<double>(
      begin: 0.0,
      end: 100.0 * widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _rotation = Tween<double>(
      begin: 0.0,
      end: 0.2,
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

  @override
  Widget build(BuildContext context) {
    final width = 36 * widget.scale;
    final height = 52 * widget.scale;
    final isRed = widget.card.suit == '♥' || widget.card.suit == '♦';
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = Offset(widget.start.dx, widget.start.dy + _offsetY.value);
        return Positioned(
          left: pos.dx - width / 2,
          top: pos.dy - height / 2,
          child: FadeTransition(
            opacity: _opacity,
            child: Transform.rotate(angle: _rotation.value, child: child),
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          '${widget.card.rank}${widget.card.suit}',
          style: TextStyle(
            color: isRed ? Colors.red : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18 * widget.scale,
          ),
        ),
      ),
    );
  }
}
