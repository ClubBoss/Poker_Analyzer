import 'package:flutter/material.dart';

import '../models/training_spot.dart';

/// Displays a single [TrainingSpot] entry inside [TrainingSpotList].
///
/// Editing and removal actions are delegated to callbacks provided by the
/// parent list so the tile remains stateless and reusable.
class TrainingSpotTile extends StatelessWidget {
  final TrainingSpot spot;
  final int index;
  final ValueChanged<int>? onEdit;
  final ValueChanged<int>? onRemove;

  const TrainingSpotTile({
    super.key,
    required this.spot,
    required this.index,
    this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final pos = spot.positions.isNotEmpty ? spot.positions[spot.heroIndex] : '';
    final stack = spot.stacks.isNotEmpty ? spot.stacks[spot.heroIndex] : 0;
    return ListTile(
      title: Text('$pos ${stack}bb'),
      subtitle: spot.tags.isNotEmpty ? Text(spot.tags.join(', ')) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit == null ? null : () => onEdit!(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onRemove == null ? null : () => onRemove!(index),
          ),
        ],
      ),
    );
  }
}
