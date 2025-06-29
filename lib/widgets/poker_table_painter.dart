import 'package:flutter/material.dart';
import 'poker_table_view.dart' show TableTheme;

class PokerTablePainter extends CustomPainter {
  final TableTheme theme;

  PokerTablePainter({this.theme = TableTheme.green});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()..addOval(rect);

    canvas.drawShadow(path, Colors.black.withOpacity(0.5), 12.0, true);

    final gradient = _gradientForTheme();
    final feltPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawOval(rect, feltPaint);

    final borderPaint = Paint()
      ..color = _borderColor().withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.03;
    canvas.drawOval(rect.deflate(borderPaint.strokeWidth / 2), borderPaint);
  }

  Gradient _gradientForTheme() {
    switch (theme) {
      case TableTheme.green:
        return const LinearGradient(
          colors: [Color(0xFF497A5E), Color(0xFF24432E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case TableTheme.carbon:
        return const LinearGradient(
          colors: [Color(0xFF444444), Color(0xFF222222)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case TableTheme.blue:
        return const LinearGradient(
          colors: [Color(0xFF00577C), Color(0xFF001F3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _borderColor() {
    switch (theme) {
      case TableTheme.green:
        return const Color(0xFFBDBDBD);
      case TableTheme.carbon:
        return Colors.grey;
      case TableTheme.blue:
        return Colors.lightBlueAccent;
    }
  }

  @override
  bool shouldRepaint(covariant PokerTablePainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}
