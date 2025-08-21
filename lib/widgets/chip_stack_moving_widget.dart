import 'package:flutter/material.dart';
import 'chip_stack_widget.dart';

/// Animates a stack of chips flying along a curved path.
class ChipStackMovingWidget extends StatefulWidget {
  /// Number of instances animating concurrently.
  static int activeCount = 0;

  /// Global start position of the animation.
  final Offset start;

  /// Global end position of the animation.
  final Offset end;

  /// Amount represented by the chip stack.
  final int amount;

  /// Color of the chips.
  final Color color;

  /// Scale factor applied to the widget.
  final double scale;

  /// Duration of the animation.
  final Duration duration;

  /// Optional control point for a quadratic bezier path.
  final Offset? control;

  /// Callback when the animation completes.
  final VoidCallback? onCompleted;

  /// Fraction of the animation after which fading should begin.
  /// Ranges from 0.0 (fade from start) to 1.0 (no fade).
  final double fadeStart;

  /// Final rotation applied to the chip stack when the animation completes.
  final double endRotation;

  /// Whether to draw an amount label on the moving chips.
  final bool showLabel;

  /// Text style for the amount label when [showLabel] is true.
  final TextStyle? labelStyle;

  /// Optional glow color applied behind the chips.
  final Color? glowColor;

  const ChipStackMovingWidget({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    required this.color,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
    this.fadeStart = 0.0,
    this.endRotation = 0.0,
    this.showLabel = false,
    this.labelStyle,
    this.duration = const Duration(milliseconds: 400),
    this.glowColor,
  }) : super(key: key);

  @override
  State<ChipStackMovingWidget> createState() => _ChipStackMovingWidgetState();
}

class _ChipStackMovingWidgetState extends State<ChipStackMovingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    ChipStackMovingWidget.activeCount++;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(widget.fadeStart, 1.0, curve: Curves.easeOut),
      ),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _rotation = Tween<double>(
      begin: 0.0,
      end: widget.endRotation,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    ChipStackMovingWidget.activeCount--;
    _controller.dispose();
    super.dispose();
  }

  Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final control = widget.control ??
            Offset(
              (widget.start.dx + widget.end.dx) / 2,
              (widget.start.dy + widget.end.dy) / 2 -
                  (40 + ChipStackMovingWidget.activeCount * 8) * widget.scale,
            );
        final pos = _bezier(
          widget.start,
          control,
          widget.end,
          _controller.value,
        );
        final sizeFactor = _scaleAnim.value * widget.scale;
        return Positioned(
          left: pos.dx - 12 * sizeFactor,
          top: pos.dy - 12 * sizeFactor,
          child: FadeTransition(
            opacity: _opacity,
            child: Transform.rotate(
              angle: _rotation.value,
              child: Transform.scale(scale: sizeFactor, child: child),
            ),
          ),
        );
      },
      child: _buildChild(),
    );
  }

  Widget _buildChild() {
    Widget stack = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        ChipStackWidget(
          amount: widget.amount,
          scale: 0.8 * widget.scale,
          color: widget.color,
        ),
        if (widget.showLabel)
          Positioned(
            top: -16 * widget.scale,
            child: Text(
              '${widget.amount}',
              style: widget.labelStyle ??
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * widget.scale,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 2),
                    ],
                  ),
            ),
          ),
      ],
    );
    if (widget.glowColor != null) {
      stack = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: widget.glowColor!.withValues(alpha: 0.8),
              blurRadius: 12 * widget.scale,
              spreadRadius: 2 * widget.scale,
            ),
          ],
        ),
        child: stack,
      );
    }
    return stack;
  }
}
