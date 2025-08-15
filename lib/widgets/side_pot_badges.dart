import 'package:flutter/material.dart';

class SidePotBadges extends StatelessWidget {
  final List<int> sidePotsChips; // in chips; order: side pot #1, #2, ...
  final double bb; // 1 BB in chips
  final EdgeInsets padding; // default EdgeInsets.zero
  const SidePotBadges({
    super.key,
    required this.sidePotsChips,
    required this.bb,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (sidePotsChips.isEmpty || bb <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: true,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < sidePotsChips.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Text(
                  'Side Pot #${i + 1}: ${(sidePotsChips[i] / bb).toStringAsFixed(1)} BB',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
