import 'package:flutter/material.dart';
import 'poker_table_view.dart' show TableTheme;

class PokerTablePainter extends CustomPainter {
  final TableTheme theme;

  PokerTablePainter({this.theme = TableTheme.green});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.shortestSide * 0.04),
    );
    final pathRRect = Path()..addRRect(rrect);

    canvas.drawShadow(
      pathRRect,
      Colors.black.withOpacity(0.5),
      12.0,
      true,
    );

    final base = _baseColor();
    final center = HSLColor.fromColor(base)
        .withLightness((HSLColor.fromColor(base).lightness + 0.10).clamp(0.0, 1.0))
        .toColor();
    final radial = RadialGradient(
      colors: [center, base],
      stops: const [0.0, 1.0],
    ).createShader(
      Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.shortestSide * 0.65,
      ),
    );
    canvas.drawRRect(rrect, Paint()..shader = radial);

    final vignette = RadialGradient(
      colors: [Colors.transparent, Colors.black.withOpacity(0.18)],
      stops: const [0.7, 1.0],
    ).createShader(
      Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.shortestSide * 0.75,
      ),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = vignette
        ..blendMode = BlendMode.darken,
    );

    final borderPaint = Paint()
      ..color = _borderColor().withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.03;
    canvas.drawRRect(
      rrect.deflate(borderPaint.strokeWidth / 2),
      borderPaint,
    );
  }

  Color _baseColor() {
    switch (theme) {
      case TableTheme.green:
        return const Color(0xFF1E5E3C);
      case TableTheme.carbon:
        return const Color(0xFF2C2F33);
      case TableTheme.blue:
        return const Color(0xFF1E3D5E);
      case TableTheme.dark:
        return const Color(0xFF1A1B1E);
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
      case TableTheme.dark:
        return Colors.orangeAccent;
    }
  }

  @override
  bool shouldRepaint(covariant PokerTablePainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}
