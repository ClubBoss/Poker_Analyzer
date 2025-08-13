import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class WinnerLabel extends StatelessWidget {
  final double scale;
  final Animation<double> opacity;
  final Animation<double> scaleAnimation;

  const WinnerLabel({
    super.key,
    required this.scale,
    required this.opacity,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -36 * scale,
      child: FadeTransition(
        opacity: opacity,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 6 * scale, vertical: 2 * scale),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8 * scale),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Выиграл банк',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
