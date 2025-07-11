import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dynamic_progress_service.dart';

class DynamicProgressCard extends StatelessWidget {
  const DynamicProgressCard({super.key});

  Widget _metric(String label, double value, double diff) {
    final color = diff >= 0 ? Colors.green : Colors.red;
    final icon = diff >= 0 ? Icons.arrow_upward : Icons.arrow_downward;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value.toStringAsFixed(label == 'Acc' ? 1 : 2),
                  style: const TextStyle(color: Colors.white)),
              if (diff != 0) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 12, color: color),
                Text(diff.abs().toStringAsFixed(label == 'Acc' ? 1 : 2),
                    style: TextStyle(color: color, fontSize: 12)),
              ]
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DynamicProgressService>();
    final last = service.latest;
    final prev = service.previous;
    final acc = last.accuracy * 100;
    final accDiff = prev == null ? 0 : (acc - prev.accuracy * 100);
    final evDiff = prev == null ? 0 : last.ev - prev.ev;
    final icmDiff = prev == null ? 0 : last.icm - prev.icm;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Динамика сессий',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _metric('Acc', acc, accDiff),
              _metric('EV', last.ev, evDiff),
              _metric('ICM', last.icm, icmDiff),
            ],
          ),
        ],
      ),
    );
  }
}
