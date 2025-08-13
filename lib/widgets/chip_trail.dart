import 'package:flutter/material.dart';

class MiniChip extends StatelessWidget {
  final Color color;
  final double size;
  const MiniChip({Key? key, required this.color, this.size = 12})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class ChipTrail extends StatelessWidget {
  final Offset start;
  final Offset end;
  final int chipCount;
  final bool visible;
  final double scale;
  final Color color;

  const ChipTrail({
    Key? key,
    required this.start,
    required this.end,
    this.chipCount = 3,
    this.visible = false,
    this.scale = 1.0,
    this.color = const Color(0xFFB22222),
  }) : super(key: key);

  Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final control =
        Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - 40 * scale);
    return IgnorePointer(
      child: Stack(
        children: List.generate(chipCount, (i) {
          final t = (i + 1) / (chipCount + 1);
          final pos = _bezier(start, control, end, t);
          return Positioned(
            left: pos.dx - 6 * scale,
            top: pos.dy - 6 * scale,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: visible ? 1.0 : 0.0,
              child: MiniChip(color: color, size: 12 * scale),
            ),
          );
        }),
      ),
    );
  }
}
