import 'package:flutter/material.dart';
import 'chip_stack_widget.dart';

/// Displays pot size for a specific street in the history panel.
class StreetPotWidget extends StatelessWidget {
  final int streetIndex;
  final int potSize;
  final int effectiveStack;

  const StreetPotWidget({
    super.key,
    required this.streetIndex,
    required this.potSize,
    required this.effectiveStack,
  });

  String get _streetName {
    const names = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'];
    if (streetIndex >= 0 && streetIndex < names.length) {
      return names[streetIndex];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (potSize <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: potSize),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          final factor = potSize > 0
              ? (value / potSize).clamp(0.0, 1.0) as double
              : 0.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ChipStackWidget(
                    amount: value,
                    scale: 0.6,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_streetName пот: $value',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (value > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      'SPR: ${(effectiveStack / value).toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: factor,
                  backgroundColor: Colors.white10,
                  color: Colors.orangeAccent,
                  minHeight: 4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
