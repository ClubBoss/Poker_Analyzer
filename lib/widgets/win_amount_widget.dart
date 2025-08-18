import 'package:flutter/material.dart';

/// Fading label displaying the amount a player won.
class WinAmountWidget extends StatefulWidget {
  final Offset position;
  final int amount;
  final double scale;
  final VoidCallback? onCompleted;

  const WinAmountWidget({
    Key? key,
    required this.position,
    required this.amount,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<WinAmountWidget> createState() => _WinAmountWidgetState();
}

class _WinAmountWidgetState extends State<WinAmountWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  String _formatAmount(int value) => value.toString();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
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
          '+${_formatAmount(widget.amount)} BB',
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16 * widget.scale,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 4 * widget.scale,
              ),
              Shadow(
                color: Colors.greenAccent.withValues(alpha: 0.8),
                blurRadius: 6 * widget.scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays a [WinAmountWidget] above the current overlay.
void showWinAmountOverlay({
  required BuildContext context,
  required Offset position,
  required int amount,
  double scale = 1.0,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => WinAmountWidget(
      position: position,
      amount: amount,
      scale: scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
