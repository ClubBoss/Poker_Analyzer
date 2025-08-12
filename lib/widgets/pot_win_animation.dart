import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'chip_stack_moving_widget.dart';

/// Animation of chips flying from the pot to a player's stack
/// with a brief flare effect at the end.
class PotWinAnimation extends StatefulWidget {
  /// Start position (typically center of the table).
  final Offset start;

  /// End position of the winning player.
  final Offset end;

  /// Chip amount to animate.
  final int amount;

  /// Chip color.
  final Color color;

  /// Scale factor applied to the animation.
  final double scale;

  /// Optional bezier control point.
  final Offset? control;

  /// Fraction of the animation after which the chip stack begins to fade out.
  final double fadeStart;

  /// Called when animation completes.
  final VoidCallback? onCompleted;

  const PotWinAnimation({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    this.color = AppColors.accent,
    this.scale = 1.0,
    this.control,
    this.fadeStart = 0.6,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<PotWinAnimation> createState() => _PotWinAnimationState();
}

class _PotWinAnimationState extends State<PotWinAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _flareController;

  @override
  void initState() {
    super.initState();
    _flareController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _flareController.dispose();
    super.dispose();
  }

  void _onChipsCompleted() {
    _flareController.forward().whenComplete(() {
      widget.onCompleted?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ChipStackMovingWidget(
          start: widget.start,
          end: widget.end,
          amount: widget.amount,
          color: widget.color,
          scale: widget.scale,
          control: widget.control,
          fadeStart: widget.fadeStart,
          onCompleted: _onChipsCompleted,
        ),
        Positioned(
          left: widget.end.dx - 20 * widget.scale,
          top: widget.end.dy - 20 * widget.scale,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _flareController,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.5).animate(
                CurvedAnimation(parent: _flareController, curve: Curves.easeOut),
              ),
              child: Container(
                width: 40 * widget.scale,
                height: 40 * widget.scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.yellow.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
