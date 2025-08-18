import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small shrinking countdown ring used to indicate the active player's turn.
class TurnCountdownOverlay extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;
  final double scale;
  final bool showSeconds;

  const TurnCountdownOverlay({
    Key? key,
    this.duration = const Duration(seconds: 3),
    this.onComplete,
    this.scale = 1.0,
    this.showSeconds = false,
  }) : super(key: key);

  @override
  State<TurnCountdownOverlay> createState() => _TurnCountdownOverlayState();
}

class _TurnCountdownOverlayState extends State<TurnCountdownOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = 1.0 - _controller.value;
        final ring = CustomPaint(
          size: Size(24 * widget.scale, 24 * widget.scale),
          painter: _RingPainter(
            progress: progress,
            color: color,
            thickness: 3 * widget.scale,
          ),
        );
        return Transform.scale(
          scale: progress,
          child: widget.showSeconds
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    ring,
                    Text(
                      '${(widget.duration.inSeconds * progress).ceil()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10 * widget.scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : ring,
        );
      },
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
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
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
