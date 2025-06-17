import 'package:flutter/material.dart';

import '../../models/training_spot.dart';
import '../../theme/app_colors.dart';

class TrainingSpotList extends StatelessWidget {
  final List<TrainingSpot> spots;
  final ValueChanged<int>? onRemove;

  const TrainingSpotList({super.key, required this.spots, this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const Text(
        'Нет импортированных спотов',
        style: TextStyle(color: Colors.white54),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        itemCount: spots.length,
        itemBuilder: (context, index) {
          final spot = spots[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (spot.tournamentId != null && spot.tournamentId!.isNotEmpty)
                        Text('ID: ${spot.tournamentId}',
                            style: const TextStyle(color: Colors.white)),
                      if (spot.buyIn != null)
                        Text('Buy-In: ${spot.buyIn}',
                            style: const TextStyle(color: Colors.white)),
                      if (spot.gameType != null && spot.gameType!.isNotEmpty)
                        Text('Game: ${spot.gameType}',
                            style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onRemove!(index),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
