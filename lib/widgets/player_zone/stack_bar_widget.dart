import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Displays player's remaining stack as a thin progress bar.
class StackBarWidget extends StatelessWidget {
  /// Current stack size. If null, the bar is hidden.
  final int? stack;

  /// Starting stack value representing 100% of the bar.
  final int maxStack;

  /// Scale factor for sizing.
  final double scale;

  /// Animation controlling the progress value of the bar. When provided, the
  /// [stack] value is used only for color determination.
  final Animation<double>? progressAnimation;

  /// Optional glow or pulse animation applied while the bar is animating.
  final Animation<double>? glowAnimation;

  const StackBarWidget({
    Key? key,
    required this.stack,
    this.maxStack = 100,
    this.scale = 1.0,
    this.progressAnimation,
    this.glowAnimation,
  }) : super(key: key);

  Color _barColor(int stack) {
    if (stack > 50) {
      return Colors.green;
    } else if (stack >= 20) {
      return Colors.yellow;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (stack == null) return SizedBox(height: 4 * scale);
    final double progress = (stack! / maxStack).clamp(0.0, 1.0);
    final color = _barColor(stack!);

    final progressAnim = progressAnimation ?? AlwaysStoppedAnimation<double>(progress);
    final glowAnim = glowAnimation ?? const AlwaysStoppedAnimation<double>(0.0);

    return SizedBox(
      height: 4 * scale,
      child: AnimatedBuilder(
        animation: Listenable.merge([progressAnim, glowAnim]),
        builder: (context, child) {
          final glow = glowAnim.value;
          return Container(
            decoration: glow > 0
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(glow),
                        blurRadius: 8 * glow * scale,
                        spreadRadius: 2 * glow * scale,
                      ),
                    ],
                  )
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2 * scale),
              child: LinearProgressIndicator(
                value: progressAnim.value,
                backgroundColor: Colors.black26,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4 * scale,
              ),
            ),
          );
        },
      ),
    );
  }
}
