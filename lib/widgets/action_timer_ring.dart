import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated ring that counts down over [duration] when [isActive] is true.
/// Calls [onTimeExpired] when the countdown completes.
class ActionTimerRing extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;
  final VoidCallback? onTimeExpired;
  final double thickness;
  final bool showCountdownText;

  const ActionTimerRing({
    super.key,
    required this.child,
    required this.isActive,
    this.duration = const Duration(seconds: 10),
    this.onTimeExpired,
    this.thickness = 4,
    this.showCountdownText = true,
  });

  @override
  State<ActionTimerRing> createState() => _ActionTimerRingState();
}

class _ActionTimerRingState extends State<ActionTimerRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _color = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.green, end: Colors.yellow),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.yellow, end: Colors.red),
        weight: 50,
      ),
    ]).animate(_controller);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTimeExpired?.call();
      }
    });
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ActionTimerRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller
        ..reset()
        ..forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reset();
    }
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
        final progress = 1.0 - _controller.value;
        final color = _color.value ?? Colors.green;
        final ring = CustomPaint(
          foregroundPainter: _RingPainter(
            progress: progress,
            color: color,
            thickness: widget.thickness,
          ),
          child: child,
        );
        if (widget.showCountdownText && widget.isActive) {
          final remainingSeconds =
              (widget.duration.inSeconds * progress).ceil();
          return Stack(
            alignment: Alignment.center,
            children: [
              ring,
              Text(
                '$remainingSeconds',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }
        return ring;
      },
      child: widget.child,
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double thickness;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2 - thickness / 2;
    final rect =
        Rect.fromCircle(center: size.center(Offset.zero), radius: radius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.thickness != thickness;
  }
}
