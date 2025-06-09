import 'package:flutter/material.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import 'training_pack_screen.dart';

class TrainingPacksScreen extends StatelessWidget {
  const TrainingPacksScreen({super.key});

  SavedHand _placeholderHand(String name) {
    return SavedHand(
      name: name,
      heroIndex: 0,
      heroPosition: 'BTN',
      numberOfPlayers: 6,
      playerCards: List.generate(6, (_) => []),
      boardCards: [],
      actions: [],
      stackSizes: const {},
      playerPositions: const {},
    );
  }

  List<TrainingPack> _packs() {
    return [
      TrainingPack(
        name: 'Push/Fold 10BB',
        description: 'Решения при стеке 10BB',
        hands: [_placeholderHand('Push/Fold 10BB')],
      ),
      TrainingPack(
        name: '3-bet без позиции',
        description: 'Тренировка игры без позиции',
        hands: [_placeholderHand('3-bet без позиции')],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final packs = _packs();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировочные пакеты'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packs.length,
        itemBuilder: (context, index) {
          final pack = packs[index];
          return Card(
            color: const Color(0xFF2A2B2E),
            child: ListTile(
              title: Text(pack.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(pack.description,
                  style: const TextStyle(color: Colors.white70)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingPackScreen(pack: pack),
                ),
              ),
            ),
          );
        },
      ),
      backgroundColor: const Color(0xFF1B1C1E),
    );
  }
}
