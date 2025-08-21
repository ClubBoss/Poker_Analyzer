import 'package:flutter/material.dart';

class ProgressChip extends StatelessWidget {
  final double pct;
  const ProgressChip(this.pct, {super.key});

  @override
  Widget build(BuildContext ctx) {
    final tint = Theme.of(ctx).colorScheme.surfaceTint;
    final color = pct >= 1
        ? tint.withValues(alpha: .9)
        : pct >= .5
            ? tint.withValues(alpha: .7)
            : tint.withValues(alpha: .5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${(pct * 100).round()}%',
        style: const TextStyle(color: Colors.black, fontSize: 12),
      ),
    );
  }
}
