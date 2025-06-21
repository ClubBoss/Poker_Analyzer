import 'package:flutter/material.dart';

class PokerTablePainter extends CustomPainter {
  final Color feltColor;
  final Color borderColor;

  PokerTablePainter({
    this.feltColor = const Color(0xFF35654D),
    this.borderColor = const Color(0xFFBDBDBD),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()..addOval(rect);

    canvas.drawShadow(path, Colors.black.withOpacity(0.5), 12.0, true);

    final feltPaint = Paint()..color = feltColor;
    canvas.drawOval(rect, feltPaint);

    final borderPaint = Paint()
      ..color = borderColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.03;
    canvas.drawOval(rect.deflate(borderPaint.strokeWidth / 2), borderPaint);
  }

  @override
  bool shouldRepaint(covariant PokerTablePainter oldDelegate) {
    return oldDelegate.feltColor != feltColor ||
        oldDelegate.borderColor != borderColor;
  }
}
