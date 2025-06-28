import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../widgets/action_history_widget.dart';
import '../widgets/eval_result_view.dart';

class TrainingSpotDetailScreen extends StatelessWidget {
  final TrainingSpot spot;

  const TrainingSpotDetailScreen({super.key, required this.spot});

  Map<int, String> _posMap() => {
        for (int i = 0; i < spot.numberOfPlayers; i++)
          if (i < spot.positions.length) i: spot.positions[i]
      };

  @override
  Widget build(BuildContext context) {
    final heroCards = spot.heroIndex < spot.playerCards.length
        ? spot.playerCards[spot.heroIndex].join(' ')
        : '';
    final board = spot.boardCards.map((c) => c.toString()).join(' ');
    final pos = spot.heroIndex < spot.positions.length
        ? spot.positions[spot.heroIndex]
        : '';
    final user = spot.userAction;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot Details'),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hero position: $pos',
              style: const TextStyle(color: Colors.white)),
          if (heroCards.isNotEmpty)
            Text('Hero cards: $heroCards',
                style: const TextStyle(color: Colors.white)),
          if (board.isNotEmpty)
            Text('Board: $board', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ActionHistoryWidget(actions: spot.actions, playerPositions: _posMap()),
          if (user != null) ...[
            const SizedBox(height: 16),
            Text('Your action: $user',
                style: const TextStyle(color: Colors.white)),
          ],
          if (spot.recommendedAction != null) ...[
            const SizedBox(height: 8),
            EvalResultView(spot: spot, action: user ?? ''),
          ],
        ],
      ),
    );
  }
}
