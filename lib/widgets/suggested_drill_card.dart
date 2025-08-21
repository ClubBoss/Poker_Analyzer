import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/drill_suggestion_engine.dart';
import '../screens/training_pack_screen.dart';
import '../services/reminder_service.dart';

class SuggestedDrillCard extends StatelessWidget {
  const SuggestedDrillCard({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<DrillSuggestionEngine>();
    if (engine.suggestedDrills.isEmpty) return const SizedBox.shrink();

    final drill = engine.suggestedDrills.first;
    final reminder = context.watch<ReminderService>();
    final key = '${drill.position}_${drill.street}';
    if (reminder.isDrillDismissed(key)) return const SizedBox.shrink();
    final card = Container(
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
                Text(
                  '${drill.position} • ${drill.street}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final pack = context.read<DrillSuggestionEngine>().startDrill(
                    drill,
                  );
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          card,
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white70),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () =>
                  context.read<ReminderService>().dismissDrillForToday(key),
            ),
          ),
        ],
      ),
    );
  }
}
