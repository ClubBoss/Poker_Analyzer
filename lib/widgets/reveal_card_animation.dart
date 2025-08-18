import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_model.dart';

/// Animation that flips a facedown card at [position] to reveal its face.
class RevealCardAnimation extends StatefulWidget {
  /// Center position of the card in global coordinates.
  final Offset position;

  /// Card to reveal.
  final CardModel card;

  /// Scale factor applied to card size.
  final double scale;

  /// Duration of the flip animation.
  final Duration duration;

  /// Callback invoked when the animation finishes.
  final VoidCallback? onCompleted;

  /// Whether to cross-fade between the back and front during the flip.
  final bool fade;

  /// Whether to desaturate the front of the card when revealed.
  final bool grayscale;

  const RevealCardAnimation({
    Key? key,
    required this.position,
    required this.card,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 400),
    this.onCompleted,
    this.fade = false,
    this.grayscale = false,
  }) : super(key: key);

  @override
  State<RevealCardAnimation> createState() => _RevealCardAnimationState();
}

class _RevealCardAnimationState extends State<RevealCardAnimation>
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
            final value = _controller.value;
            double angle = value * pi;

            final back = Image.asset(
              'assets/cards/card_back.png',
              width: width,
              height: height,
            );

            Widget front = Container(
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

            if (widget.grayscale) {
              front = ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.saturation,
                ),
                child: front,
              );
            }

            if (widget.fade) {
              final backOpacity = value <= 0.5 ? 1 - value * 2 : 0.0;
              final frontOpacity = value <= 0.5 ? 0.0 : (value - 0.5) * 2;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: backOpacity,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: back,
                    ),
                  ),
                  Opacity(
                    opacity: frontOpacity,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle - pi),
                      alignment: Alignment.center,
                      child: front,
                    ),
                  ),
                ],
              );
            }

            Widget display;
            if (value <= 0.5) {
              display = back;
            } else {
              angle -= pi;
              display = front;
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
