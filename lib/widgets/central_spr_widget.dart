import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Displays the Stack-to-Pot Ratio (SPR) in the center of the table.
class CentralSprWidget extends StatelessWidget {
  /// Formatted SPR text to display.
  final String text;

  /// Scale factor for sizing.
  final double scale;

  const CentralSprWidget({Key? key, required this.text, this.scale = 1.0})
    : super(key: key);

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
          vertical: 4 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
            fontSize: 14 * scale,
          ),
        ),
      ),
    );
  }
}
