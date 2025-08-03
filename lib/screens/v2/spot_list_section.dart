import 'package:flutter/material.dart';

import '../../models/v2/training_pack_spot.dart';

class SpotListSection extends StatelessWidget {
  final List<TrainingPackSpot> spots;
  final VoidCallback? onAdd;

  const SpotListSection({
    super.key,
    required this.spots,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final spot = spots[index];
              return ListTile(
                title: Text(spot.title),
                subtitle: Text(spot.tags.join(', ')),
              );
            },
          ),
        ),
        if (onAdd != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: onAdd,
              child: const Text('Add Spot'),
            ),
          ),
      ],
    );
  }
}
