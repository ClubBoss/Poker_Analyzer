import "package:flutter/material.dart";
class ProgressChip extends StatelessWidget {
  final double pct;
  const ProgressChip(this.pct, {super.key});
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: pct >= 1
              ? Colors.green
              : pct >= .5
                  ? Colors.amber
                  : Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('${(pct * 100).round()}%',
            style: const TextStyle(color: Colors.black, fontSize: 12)),
      );
}
