import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const BadgeIcon(this.icon, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Colors.orange, Colors.yellowAccent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
        child: Icon(icon, size: size, color: Colors.white),
      ),
    );
  }
}
