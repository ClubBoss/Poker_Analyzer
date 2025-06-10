import 'package:flutter/material.dart';

class ChipAnimationData {
  final Offset start;
  final Offset end;
  final int amount;
  final Color color;
  final double scale;
  final AnimationController controller;
  ChipAnimationData({
    required this.start,
    required this.end,
    required this.amount,
    required this.color,
    required this.scale,
    required this.controller,
  });
}

class ChipAnimationOverlay extends StatelessWidget {
  final List<ChipAnimationData> animations;
  const ChipAnimationOverlay({Key? key, required this.animations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final a in animations) _AnimatedChip(data: a),
        ],
      ),
    );
  }
}

class _AnimatedChip extends StatelessWidget {
  final ChipAnimationData data;
  const _AnimatedChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: data.controller,
      builder: (context, child) {
        final pos = Offset.lerp(data.start, data.end, data.controller.value)!;
        return Positioned(
          left: pos.dx - 12 * data.scale,
          top: pos.dy - 12 * data.scale,
          child: Opacity(
            opacity: 1.0 - data.controller.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 24 * data.scale,
        height: 24 * data.scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: data.color,
        ),
        child: Text(
          '${data.amount}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12 * data.scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
