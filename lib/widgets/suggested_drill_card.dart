import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/drill_suggestion_engine.dart';
import '../screens/training_pack_screen.dart';

class SuggestedDrillCard extends StatelessWidget {
  const SuggestedDrillCard({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<DrillSuggestionEngine>();
    if (engine.suggestedDrills.isEmpty) return const SizedBox.shrink();
    final drill = engine.suggestedDrills.first;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, color: Colors.greenAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggested Drill',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('${drill.position} • ${drill.street}',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final pack = context.read<DrillSuggestionEngine>().startDrill(drill);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingPackScreen(
                    pack: pack,
                    hands: pack.hands,
                    persistResults: false,
                  ),
                ),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
