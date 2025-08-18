import 'package:flutter/material.dart';

class StreetCoverageBar extends StatelessWidget {
  final List<int> totals;
  final List<int> covered;
  const StreetCoverageBar({
    super.key,
    required this.totals,
    required this.covered,
  });

  Color _color(int index) {
    final total = totals[index];
    if (total == 0) return Colors.grey;
    final pct = covered[index] * 100 / total;
    if (pct < 50) return Colors.red;
    if (pct < 90) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Pre', 'Flop', 'Turn', 'River'];
    final totalAll = totals.fold<int>(0, (a, b) => a + b);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double segmentWidth(int i) {
          final total = totals[i];
          if (totalAll == 0) return width / 4;
          return width * total / totalAll;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (int i = 0; i < 4; i++)
                  Container(
                    width: segmentWidth(i),
                    height: 6,
                    color: _color(i).withValues(alpha: totals[i] == 0 ? .3 : 1),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                for (final l in labels)
                  Expanded(
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white54,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
