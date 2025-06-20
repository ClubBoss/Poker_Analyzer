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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
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
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * widget.scale,
            vertical: 4 * widget.scale,
          ),
          decoration: BoxDecoration(
            color: Colors.amberAccent.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8 * widget.scale),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
          ),
          child: Text(
            'Выигрыш: ${widget.amount}',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14 * widget.scale,
            ),
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
  if (overlay == null) return;
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
