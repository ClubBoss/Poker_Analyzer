import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../helpers/poker_street_helper.dart';

class MistakeHeatmap extends StatelessWidget {
  final Map<String, Map<String, int>> data;
  const MistakeHeatmap({super.key, required this.data});

  Widget _cell(int value, int maxValue) {
    final t = maxValue > 0 ? value / maxValue : 0.0;
    final color = Color.lerp(Colors.transparent, Colors.redAccent, t)!;
    return Container(
      height: 32,
      alignment: Alignment.center,
      color: color,
      child: Text('$value', style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const positions = ['BB', 'SB', 'BTN', 'CO', 'MP', 'UTG'];
    const streets = kStreetNames;
    final maxVal = positions
        .expand((p) => streets.map((s) => data[p]?[s] ?? 0))
        .fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.all(color: Colors.white24),
        defaultColumnWidth: const FlexColumnWidth(),
        children: [
          TableRow(children: [
            const SizedBox.shrink(),
            for (final s in streets)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(s,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
          ]),
          for (final p in positions)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(p,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              for (final s in streets) _cell(data[p]?[s] ?? 0, maxVal),
            ]),
        ],
      ),
    );
  }
}
