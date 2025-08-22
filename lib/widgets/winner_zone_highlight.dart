import 'package:flutter/material.dart';

/// Animated border highlight shown around the winning player's zone.
class WinnerZoneHighlight extends StatefulWidget {
  final Rect rect;
  final double scale;
  final VoidCallback? onCompleted;

  const WinnerZoneHighlight({
    Key? key,
    required this.rect,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<WinnerZoneHighlight> createState() => _WinnerZoneHighlightState();
}

class _WinnerZoneHighlightState extends State<WinnerZoneHighlight>
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
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_controller);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.95,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
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
      left: widget.rect.left,
      top: widget.rect.top,
      width: widget.rect.width,
      height: widget.rect.height,
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12 * widget.scale),
                border: Border.all(
                  color: Colors.amberAccent,
                  width: 2 * widget.scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amberAccent.withValues(alpha: 0.8),
                    blurRadius: 20 * widget.scale,
                    spreadRadius: 4 * widget.scale,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inserts a [WinnerZoneHighlight] using an [OverlayEntry].
void showWinnerZoneHighlightOverlay({
  required BuildContext context,
  required Rect rect,
  double scale = 1.0,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => WinnerZoneHighlight(
      rect: rect,
      scale: scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
