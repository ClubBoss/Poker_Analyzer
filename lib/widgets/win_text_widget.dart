import 'package:flutter/material.dart';

/// Floating label indicating which player won the pot.
class WinTextWidget extends StatefulWidget {
  final Offset position;
  final String text;
  final double scale;
  final VoidCallback? onCompleted;

  const WinTextWidget({
    Key? key,
    required this.position,
    required this.text,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<WinTextWidget> createState() => _WinTextWidgetState();
}

class _WinTextWidgetState extends State<WinTextWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

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
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 20,
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
              horizontal: 8 * widget.scale,
              vertical: 4 * widget.scale,
            ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8 * widget.scale),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: Colors.white,
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

/// Show a [WinTextWidget] above the current overlay.
void showWinTextOverlay({
  required BuildContext context,
  required Offset position,
  required String text,
  double scale = 1.0,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => WinTextWidget(
      position: position,
      text: text,
      scale: scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
