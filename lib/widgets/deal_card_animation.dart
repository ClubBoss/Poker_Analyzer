import 'package:flutter/material.dart';
import '../models/card_model.dart';

/// Animation for dealing a card from the center of the table to a target
/// position. The card scales up and rotates slightly while moving.
class DealCardAnimation extends StatefulWidget {
  final Offset start;
  final Offset end;
  final CardModel card;
  final double scale;
  final Duration duration;
  final VoidCallback? onCompleted;

  const DealCardAnimation({
    Key? key,
    required this.start,
    required this.end,
    required this.card,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 400),
    this.onCompleted,
  }) : super(key: key);

  @override
  State<DealCardAnimation> createState() => _DealCardAnimationState();
}

class _DealCardAnimationState extends State<DealCardAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotation;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _rotation = Tween<double>(begin: -0.4, end: 0.0).animate(_progress);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3)),
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

  @override
  Widget build(BuildContext context) {
    final width = 36 * widget.scale;
    final height = 52 * widget.scale;
    final isRed = widget.card.suit == '♥' || widget.card.suit == '♦';
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = Offset.lerp(widget.start, widget.end, _progress.value)!;
        return Positioned(
          left: pos.dx - width / 2,
          top: pos.dy - height / 2,
          child: FadeTransition(
            opacity: _opacity,
            child: Transform.rotate(
              angle: _rotation.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 3,
              offset: const Offset(1, 2),
            )
          ],
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
