import 'package:flutter/material.dart';

class PositionLabel extends StatelessWidget {
  final String label;
  final bool isHero;
  final double scale;
  const PositionLabel({
    super.key,
    required this.label,
    required this.isHero,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      key: ValueKey('${label}_$isHero'),
      style: TextStyle(
        color: isHero ? Colors.white : Colors.grey,
        fontSize: (isHero ? 12 : 10) * scale,
        fontWeight: isHero ? FontWeight.bold : FontWeight.normal,
      ),
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: text,
    );
  }
}
