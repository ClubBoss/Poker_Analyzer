import 'package:flutter/material.dart';

import 'combined_progress_bar.dart';

class CombinedProgressChangeBar extends StatelessWidget {
  final double prevEvPct;
  final double prevIcmPct;
  final double evPct;
  final double icmPct;

  const CombinedProgressChangeBar({
    super.key,
    required this.prevEvPct,
    required this.prevIcmPct,
    required this.evPct,
    required this.icmPct,
  });

  @override
  Widget build(BuildContext context) {
    final deltaEv = evPct - prevEvPct;
    final deltaIcm = icmPct - prevIcmPct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CombinedProgressBar(evPct, icmPct),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              deltaEv >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: deltaEv >= 0 ? Colors.green : Colors.red,
            ),
            Text(
              '${deltaEv.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: deltaEv >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              deltaIcm >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: deltaIcm >= 0 ? Colors.green : Colors.red,
            ),
            Text(
              '${deltaIcm.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: deltaIcm >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
