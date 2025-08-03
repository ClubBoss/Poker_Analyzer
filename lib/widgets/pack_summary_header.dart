import 'package:flutter/material.dart';

import '../models/training_pack.dart';
import 'difficulty_chip.dart';
import 'info_tooltip.dart';

class PackSummaryHeader extends StatelessWidget {
  final TrainingPack pack;
  const PackSummaryHeader({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final subtitleCount =
        pack.spots.isNotEmpty ? '${pack.spots.length} spots' : '${pack.hands.length} hands';
    return ListTile(
      leading: pack.isBuiltIn
          ? const Text('📦')
          : InfoTooltip(
              message: pack.colorTag.isEmpty
                  ? 'No color tag'
                  : 'Color tag ${pack.colorTag}',
              child: const Icon(Icons.label, color: Colors.white70),
            ),
      title: Text(pack.name),
      subtitle: Text(subtitleCount),
      trailing: DifficultyChip(pack.difficulty),
    );
  }
}

