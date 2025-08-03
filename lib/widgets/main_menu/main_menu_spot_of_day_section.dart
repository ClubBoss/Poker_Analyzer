import 'package:flutter/material.dart';

import '../../models/training_spot.dart';
import '../../screens/training_screen.dart';
import '../../utils/responsive.dart';
import '../../widgets/training_spot_preview.dart';

class MainMenuSpotOfDaySection extends StatelessWidget {
  final TrainingSpot spot;

  const MainMenuSpotOfDaySection({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: responsiveSize(context, 24)),
      padding: responsiveAll(context, 12),
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
          Text(
            'Hero stack: ${spot.stacks[spot.heroIndex]}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'Positions: ${spot.positions.join(', ')}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          TrainingSpotPreview(spot: spot),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrainingScreen(spot: spot)),
                );
              },
              child: const Text('Start'),
            ),
          ),
        ],
      ),
    );
  }
}

