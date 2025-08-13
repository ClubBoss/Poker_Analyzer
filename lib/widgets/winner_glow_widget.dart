import 'package:flutter/material.dart';

/// Small fade-in/out badge displayed above the winning player's avatar.
class WinnerGlowWidget extends StatefulWidget {
  final Offset position;
  final double scale;
  final VoidCallback? onCompleted;

  const WinnerGlowWidget({
    Key? key,
    required this.position,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<WinnerGlowWidget> createState() => _WinnerGlowWidgetState();
}

class _WinnerGlowWidgetState extends State<WinnerGlowWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
    ]).animate(_controller);
    _scale = Tween<double>(begin: 0.9, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
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
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6 * widget.scale,
              vertical: 2 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: Colors.amberAccent,
              borderRadius: BorderRadius.circular(8 * widget.scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.7),
                  blurRadius: 8 * widget.scale,
                  spreadRadius: 1 * widget.scale,
                ),
              ],
            ),
            child: Text(
              'Winner',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14 * widget.scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Display a [WinnerGlowWidget] above the current overlay.
void showWinnerGlowOverlay({
  required BuildContext context,
  required Offset position,
  double scale = 1.0,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => WinnerGlowWidget(
      position: position,
      scale: scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
