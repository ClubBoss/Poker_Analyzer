import 'package:flutter/material.dart';

import '../../models/v2/training_pack_spot.dart';

class StatisticsPane extends StatelessWidget {
  final List<TrainingPackSpot> spots;

  const StatisticsPane({
    super.key,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    final total = spots.length;
    final pinned = spots.where((s) => s.pinned).length;
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistics', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Total spots: '+total.toString()),
          Text('Pinned spots: '+pinned.toString()),
        ],
      ),
    );
  }
}
