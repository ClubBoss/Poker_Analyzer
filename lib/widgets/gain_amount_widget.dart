import 'package:flutter/material.dart';

/// Fading label displaying the amount a player gained.
class GainAmountWidget extends StatefulWidget {
  final Offset position;
  final int amount;
  final double scale;
  final VoidCallback? onCompleted;

  const GainAmountWidget({
    Key? key,
    required this.position,
    required this.amount,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<GainAmountWidget> createState() => _GainAmountWidgetState();
}

class _GainAmountWidgetState extends State<GainAmountWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
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
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: _opacity,
        child: Text(
          '+${widget.amount}',
          style: TextStyle(
            color: Colors.lightGreenAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16 * widget.scale,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 4 * widget.scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays a [GainAmountWidget] above the current overlay.
void showGainAmountOverlay({
  required BuildContext context,
  required Offset position,
  required int amount,
  double scale = 1.0,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => GainAmountWidget(
      position: position,
      amount: amount,
      scale: scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
