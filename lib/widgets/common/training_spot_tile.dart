import 'package:flutter/material.dart';

import '../../models/training_spot.dart';
import 'inline_theory_badge.dart';

class TrainingSpotTile extends StatelessWidget {
  final TrainingSpot spot;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const TrainingSpotTile({
    super.key,
    required this.spot,
    this.onEdit,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pos = spot.positions.isNotEmpty ? spot.positions[spot.heroIndex] : '';
    final stack = spot.stacks.isNotEmpty ? spot.stacks[spot.heroIndex] : 0;
    return ListTile(
      title: Text('$pos ${stack}bb'),
      subtitle: spot.tags.isNotEmpty ? Text(spot.tags.join(', ')) : null,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InlineTheoryBadge(
            tags: spot.tags,
            spotId: spot.createdAt.toIso8601String(),
          ),
          if (onEdit != null)
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          if (onRemove != null)
            IconButton(icon: const Icon(Icons.delete), onPressed: onRemove),
        ],
      ),
    );
  }
}
