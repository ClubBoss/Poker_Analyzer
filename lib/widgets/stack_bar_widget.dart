import 'package:flutter/material.dart';

/// Displays player's remaining stack as a thin progress bar.
class StackBarWidget extends StatelessWidget {
  /// Current stack size. If null, the bar is hidden.
  final int? stack;

  /// Starting stack value representing 100% of the bar.
  final int maxStack;

  /// Scale factor for sizing.
  final double scale;

  const StackBarWidget({
    Key? key,
    required this.stack,
    this.maxStack = 100,
    this.scale = 1.0,
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
    return SizedBox(
      height: 4 * scale,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(2 * scale),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4 * scale,
            ),
          );
        },
      ),
    );
  }
}
