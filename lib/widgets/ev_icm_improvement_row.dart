import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/progress_forecast_service.dart';

class EvIcmImprovementRow extends StatelessWidget {
  final int sessions;
  const EvIcmImprovementRow({super.key, this.sessions = 5});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ProgressForecastService>();
    final hist = service.history;
    if (hist.length <= 1) return const SizedBox.shrink();
    final prev = service.avgPrevEvIcm(sessions);
    final last = hist.last;
    final evDelta = last.ev - prev.key;
    final icmDelta = last.icm - prev.value;
    Widget item(String label, double v) {
      final up = v >= 0;
      final color = up ? Colors.green : Colors.red;
      final icon = up ? Icons.trending_up : Icons.trending_down;
      return Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '$label ${(v >= 0 ? '+' : '')}${v.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          item('EV', evDelta),
          const SizedBox(width: 12),
          item('ICM', icmDelta),
        ],
      ),
    );
  }
}
