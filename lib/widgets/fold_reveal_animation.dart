import 'package:flutter/material.dart';
import '../models/card_model.dart';

/// Animation used to fade and slide a revealed card off the table when
/// a player loses at showdown.
class FoldRevealAnimation extends StatefulWidget {
  final Offset start;
  final CardModel card;
  final double scale;
  final Duration duration;
  final double direction; // 1 for right, -1 for left
  final VoidCallback? onCompleted;

  const FoldRevealAnimation({
    Key? key,
    required this.start,
    required this.card,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 700),
    this.direction = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<FoldRevealAnimation> createState() => _FoldRevealAnimationState();
}

class _FoldRevealAnimationState extends State<FoldRevealAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0)),
    );
    _offset = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(widget.direction * 60 * widget.scale, 80 * widget.scale),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
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
        final pos = widget.start + _offset.value;
        return Positioned(
          left: pos.dx - width / 2,
          top: pos.dy - height / 2,
          child: FadeTransition(
            opacity: _opacity,
            child: Transform.scale(scale: _scaleAnim.value, child: child),
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
