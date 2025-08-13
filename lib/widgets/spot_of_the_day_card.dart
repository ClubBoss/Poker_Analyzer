import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/spot_of_the_day_service.dart';
import '../screens/training_screen.dart';
import '../screens/spot_of_the_day_history_screen.dart';
import 'training_spot_preview.dart';

class SpotOfTheDayCard extends StatelessWidget {
  const SpotOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final spot = context.watch<SpotOfTheDayService>().currentSpot;
    if (spot == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spot of the Day',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Hero stack: ${spot.stacks[spot.heroIndex]}',
              style: const TextStyle(color: Colors.white70)),
          Text('Positions: ${spot.positions.join(', ')}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          TrainingSpotPreview(spot: spot),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TrainingScreen(spot: spot)),
                  );
                },
                child: const Text('Play'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SpotOfTheDayHistoryScreen()),
                  );
                },
                child: const Text('History'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
