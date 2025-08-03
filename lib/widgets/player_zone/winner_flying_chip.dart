import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class WinnerFlyingChip extends StatefulWidget {
  final Offset start;
  final Offset end;
  final double scale;
  final Offset? control;
  final VoidCallback? onCompleted;

  const WinnerFlyingChip({
    Key? key,
    required this.start,
    required this.end,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<WinnerFlyingChip> createState() => _WinnerFlyingChipState();
}

class _WinnerFlyingChipState extends State<WinnerFlyingChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = TweenSequence<double>([
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.2)
        .chain(CurveTween(curve: Curves.easeOut))
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
        final control = widget.control ?? Offset(
          (widget.start.dx + widget.end.dx) / 2,
          (widget.start.dy + widget.end.dy) / 2 - 40 * widget.scale,
        );
        final pos = _bezier(widget.start, control, widget.end, _controller.value);
        final sizeFactor = _scaleAnim.value * widget.scale;
        return Positioned(
          left: pos.dx - 12 * sizeFactor,
          top: pos.dy - 12 * sizeFactor,
          child: FadeTransition(
            opacity: _opacity,
            child: Transform.scale(scale: sizeFactor, child: child),
          ),
        );
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4 * widget.scale,
              offset: const Offset(1, 2),
            )
          ],
        ),
      ),
    );
  }
}
