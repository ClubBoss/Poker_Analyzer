import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_pack_storage_service.dart';

class ProgressSummaryBox extends StatelessWidget {
  const ProgressSummaryBox({super.key});

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<TrainingPackStorageService>().packs;
    final list = [
      for (final p in packs)
        if (!p.isBuiltIn && p.history.isNotEmpty) p
    ];
    final count = list.length;
    final avg = count == 0
        ? 0.0
        : list.map((p) => p.pctComplete).reduce((a, b) => a + b) / count;
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
          Text('Паков с прогрессом: $count',
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Средний прогресс: ${(avg * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
