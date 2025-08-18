import 'package:flutter/material.dart';
import 'chip_widget.dart';

/// Animation of the pot flying to the winning player's position.
class WinPotAnimation extends StatefulWidget {
  /// Global start position (usually center of the table).
  final Offset start;

  /// Global end position of the winning player.
  final Offset end;

  /// Amount displayed on the chips.
  final int amount;

  /// Scale factor for sizing.
  final double scale;

  /// Called when the animation completes.
  final VoidCallback? onCompleted;

  const WinPotAnimation({
    super.key,
    required this.start,
    required this.end,
    required this.amount,
    this.scale = 1.0,
    this.onCompleted,
  });

  @override
  State<WinPotAnimation> createState() => _WinPotAnimationState();
}

class _WinPotAnimationState extends State<WinPotAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = Offset.lerp(widget.start, widget.end, _controller.value)!;
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: FadeTransition(opacity: _opacity, child: child),
        );
      },
      child: ChipWidget(amount: widget.amount, scale: widget.scale),
    );
  }
}

/// Helper to display [WinPotAnimation] above the current screen using an [Overlay].
void showWinPotAnimation({
  required BuildContext context,
  required Offset start,
  required Offset end,
  required int amount,
  double scale = 1.0,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => WinPotAnimation(
      start: start,
      end: end,
      amount: amount,
      scale: scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
