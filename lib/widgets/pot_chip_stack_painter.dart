import 'package:flutter/material.dart';

class PotChipStackPainter extends CustomPainter {
  final int chipCount;
  final Color color;
  PotChipStackPainter({this.chipCount = 4, this.color = Colors.orange});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final spacing = radius * 0.7;
    for (int i = 0; i < chipCount; i++) {
      final center = Offset(
        size.width / 2,
        size.height - radius - i * spacing,
      );
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [color, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius / 2);
      canvas.drawCircle(center.translate(1, 2), radius, shadow);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PotChipStackPainter oldDelegate) {
    return oldDelegate.chipCount != chipCount || oldDelegate.color != color;
  }
}
