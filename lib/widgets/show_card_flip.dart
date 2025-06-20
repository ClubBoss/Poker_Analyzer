import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_model.dart';

/// Animated flip transition showing a single card face.
///
/// Displays the card back initially then flips to reveal the
/// front. The widget is positioned globally at [position].
class ShowCardFlip extends StatefulWidget {
  /// Global position of the card's center.
  final Offset position;

  /// Card to display on the front.
  final CardModel card;

  /// Scale factor applied to card size.
  final double scale;

  /// Duration of the flip animation.
  final Duration duration;

  final VoidCallback? onCompleted;

  const ShowCardFlip({
    Key? key,
    required this.position,
    required this.card,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 400),
    this.onCompleted,
  }) : super(key: key);

  @override
  State<ShowCardFlip> createState() => _ShowCardFlipState();
}

class _ShowCardFlipState extends State<ShowCardFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onCompleted?.call();
        }
      })
      ..forward();
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
    return Positioned(
      left: widget.position.dx - width / 2,
      top: widget.position.dy - height / 2,
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double value = _controller.value;
            double angle = value * pi;
            Widget display;
            if (value <= 0.5) {
              display = Image.asset(
                'assets/cards/card_back.png',
                width: width,
                height: height,
              );
            } else {
              angle -= pi;
              display = Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${widget.card.rank}${widget.card.suit}',
                  style: TextStyle(
                    color: isRed ? Colors.red : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18 * widget.scale,
                  ),
                ),
              );
            }
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              alignment: Alignment.center,
              child: display,
            );
          },
        ),
      ),
    );
  }
}
