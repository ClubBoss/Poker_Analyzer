import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dynamic_progress_service.dart';

class DynamicProgressCard extends StatelessWidget {
  const DynamicProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<DynamicProgressService>().current;
    final delta = context.watch<DynamicProgressService>().delta;
    Widget item(String title, double value, double diff) {
      final color = diff > 0
          ? Colors.greenAccent
          : diff < 0
              ? Colors.redAccent
              : Colors.white70;
      final sign = diff > 0 ? '+' : '';
      return Expanded(
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(value.toStringAsFixed(title == 'Acc' ? 2 : 2),
                style: const TextStyle(color: Colors.white)),
            Text('$sign${diff.toStringAsFixed(title == 'Acc' ? 2 : 2)}',
                style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      );
    }

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
          const Text('Динамика последних раздач',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              item('Acc', current.accuracy * 100, delta.accuracy * 100),
              item('EV', current.ev, delta.ev),
              item('ICM', current.icm, delta.icm),
            ],
          ),
        ],
      ),
    );
  }
}
