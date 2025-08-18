import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2/hero_position.dart';
import '../services/player_progress_service.dart';

class PositionProgressCard extends StatelessWidget {
  const PositionProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<PlayerProgressService>().progress;
    if (progress.isEmpty) return const SizedBox.shrink();
    final rows = <TableRow>[];
    rows.add(
      const TableRow(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Text('Pos', style: TextStyle(color: Colors.white70)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Text('Acc', style: TextStyle(color: Colors.white70)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Text('EV', style: TextStyle(color: Colors.white70)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Text('ICM', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
    for (final p in kPositionOrder) {
      final stat = progress[p];
      if (stat == null) continue;
      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(p.label, style: const TextStyle(color: Colors.white)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${(stat.accuracy * 100).round()}%',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                stat.ev.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                stat.icm.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
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
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(40),
          2: FixedColumnWidth(50),
          3: FixedColumnWidth(50),
        },
        children: rows,
      ),
    );
  }
}
