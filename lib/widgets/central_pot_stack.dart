import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'chip_stack_widget.dart';

/// Animated chip stack visualization of the central pot.
class CentralPotStack extends StatelessWidget {
  /// Amount of chips currently in the pot.
  final int amount;

  /// Scale factor for sizing.
  final double scale;

  const CentralPotStack({Key? key, required this.amount, this.scale = 1.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: ChipStackWidget(
        key: ValueKey(amount),
        amount: amount,
        scale: scale,
        color: AppColors.accent,
      ),
    );
  }
}
