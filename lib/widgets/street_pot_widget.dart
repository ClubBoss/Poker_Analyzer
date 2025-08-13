import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'chip_stack_widget.dart';

/// Displays pot size for a specific street in the history panel.
class StreetPotWidget extends StatelessWidget {
  final int streetIndex;
  final int potSize;
  final double? sprValue;

  const StreetPotWidget({
    super.key,
    required this.streetIndex,
    required this.potSize,
    this.sprValue,
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
          final factor = potSize > 0 ? (value / potSize).clamp(0.0, 1.0) : 0.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ChipStackWidget(
                    amount: value,
                    scale: 0.6,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_streetName пот: $value',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (sprValue != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'SPR: ${sprValue!.toStringAsFixed(1)}',
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
                  color: AppColors.accent,
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
