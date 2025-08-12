import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Displays the hero's strategy range in a 13x13 hand grid.
class HeroRangeGridWidget extends StatelessWidget {
  final List<List<double>> rangeMatrix;

  const HeroRangeGridWidget({super.key, required this.rangeMatrix});

  static const _ranks = [
    'A',
    'K',
    'Q',
    'J',
    'T',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
    '2'
  ];

  String _label(int row, int col) {
    final r1 = _ranks[row];
    final r2 = _ranks[col];
    if (row == col) return '$r1$r2';
    if (row < col) return '$r1${r2}s';
    return '$r2${r1}o';
  }

  Color _cellColor(double freq) {
    final clamped = freq.clamp(0.0, 1.0);
    if (clamped >= 0.5) {
      return AppColors.accent;
    }
    if (clamped >= 0.2) {
      return Colors.red.shade900;
    }
    return Colors.grey.withValues(alpha: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < 13; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int col = 0; col < 13; col++)
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.all(1),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _cellColor(rangeMatrix[row][col]),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: Text(
                    _label(row, col),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
