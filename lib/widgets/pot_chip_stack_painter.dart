import 'package:flutter/material.dart';

class PotChipStackPainter extends CustomPainter {
  final int chipCount;
  final Color color;
  PotChipStackPainter({this.chipCount = 4, this.color = Colors.orange});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final chipSize = radius * 2;
    final centerX = size.width / 2;
    final baseY = size.height - radius;

    // shadow under pot stack
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final w = chipSize * 1.8;
    final h = chipSize * 0.5;
    final rectShadow = Rect.fromCenter(
      center: Offset(centerX, baseY + chipSize * 0.35),
      width: w,
      height: h,
    );
    canvas.drawOval(rectShadow, shadowPaint);

    final spacing = radius * 0.7;
    for (int i = 0; i < chipCount; i++) {
      final center = Offset(
        centerX,
        baseY - i * spacing,
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
