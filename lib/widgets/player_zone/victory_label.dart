import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class VictoryLabel extends StatelessWidget {
  final double scale;
  final Animation<double> opacity;

  const VictoryLabel({
    super.key,
    required this.scale,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -52 * scale,
      child: FadeTransition(
        opacity: opacity,
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
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
            '🏆 Победа!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
