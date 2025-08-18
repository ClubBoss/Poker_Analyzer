import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'chip_trail.dart';

/// Pot display widget positioned in the middle of the table.
class CentralPotWidget extends StatelessWidget {
  /// Formatted pot text to display.
  final String text;

  /// Scale factor for sizing.
  final double scale;

  /// Whether to show a chip icon next to the text.
  final bool showChip;

  const CentralPotWidget({
    Key? key,
    required this.text,
    this.scale = 1.0,
    this.showChip = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey(text),
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 6 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showChip) ...[
              MiniChip(color: AppColors.accent, size: 14 * scale),
              SizedBox(width: 6 * scale),
            ],
            Text(
              text,
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
