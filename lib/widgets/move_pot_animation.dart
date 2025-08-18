import 'package:flutter/material.dart';

/// Animation of a small "Pot" label flying to the winning player.
class MovePotAnimation extends StatefulWidget {
  /// Global start position (usually the center of the screen).
  final Offset start;

  /// Global end position of the player.
  final Offset end;

  /// Scale factor for sizing.
  final double scale;

  /// Callback invoked when the animation completes.
  final VoidCallback? onCompleted;

  const MovePotAnimation({
    Key? key,
    required this.start,
    required this.end,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<MovePotAnimation> createState() => _MovePotAnimationState();
}

class _MovePotAnimationState extends State<MovePotAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0)),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = Offset.lerp(widget.start, widget.end, _controller.value)!;
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: FadeTransition(opacity: _fade, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * widget.scale,
          vertical: 4 * widget.scale,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12 * widget.scale),
        ),
        child: Text(
          'Pot',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14 * widget.scale,
          ),
        ),
      ),
    );
  }
}

/// Displays a [MovePotAnimation] above the current overlay.
void showMovePotAnimation({
  required BuildContext context,
  required Offset start,
  required Offset end,
  double scale = 1.0,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => MovePotAnimation(
      start: start,
      end: end,
      scale: scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
