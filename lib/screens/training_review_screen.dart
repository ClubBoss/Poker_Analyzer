import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../theme/app_colors.dart';
import '../widgets/training_spot_preview.dart';

class TrainingReviewScreen extends StatelessWidget {
  final String title;
  final TrainingSpot spot;

  const TrainingReviewScreen({
    super.key,
    required this.title,
    required this.spot,
  });

  @override
  Widget build(BuildContext context) {
    final tournamentRows = <Widget>[];
    if (spot.tournamentId != null && spot.tournamentId!.isNotEmpty) {
      tournamentRows.add(
        Text('ID: ${spot.tournamentId}',
            style: const TextStyle(color: Colors.white70)),
      );
    }
    if (spot.buyIn != null) {
      tournamentRows.add(
        Text('Buy-In: ${spot.buyIn}',
            style: const TextStyle(color: Colors.white70)),
      );
    }
    if (spot.totalPrizePool != null) {
      tournamentRows.add(
        Text('Prize Pool: ${spot.totalPrizePool}',
            style: const TextStyle(color: Colors.white70)),
      );
    }
    if (spot.numberOfEntrants != null) {
      tournamentRows.add(
        Text('Entrants: ${spot.numberOfEntrants}',
            style: const TextStyle(color: Colors.white70)),
      );
    }
    if (spot.gameType != null && spot.gameType!.isNotEmpty) {
      tournamentRows.add(
        Text('Game: ${spot.gameType}',
            style: const TextStyle(color: Colors.white70)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot Review'),
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            if (tournamentRows.isNotEmpty) ...[
              const Text(
                'Tournament Info',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...tournamentRows,
              const SizedBox(height: 8),
            ],
            TrainingSpotPreview(spot: spot),
          ],
        ),
      ),
    );
  }
}
