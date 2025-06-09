import 'package:flutter/material.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import 'training_pack_screen.dart';
import 'create_pack_screen.dart';

class TrainingPacksScreen extends StatefulWidget {
  const TrainingPacksScreen({super.key});

  @override
  State<TrainingPacksScreen> createState() => _TrainingPacksScreenState();
}

class _TrainingPacksScreenState extends State<TrainingPacksScreen> {
  String _selectedCategory = 'All';
  final List<TrainingPack> _packsList = [];

  @override
  void initState() {
    super.initState();
    _packsList.addAll(_defaultPacks());
  }

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
      expectedAction: 'Push',
      feedbackText: 'При стеке 10BB это стандартный пуш.',
    );
  }

  List<TrainingPack> _defaultPacks() {
    return [
      TrainingPack(
        name: 'Push/Fold 10BB',
        description: 'Решения при стеке 10BB',
        category: 'Preflop',
        hands: [_placeholderHand('Push/Fold 10BB')],
      ),
      TrainingPack(
        name: '3-bet без позиции',
        description: 'Тренировка игры без позиции',
        category: 'Preflop',
        hands: [_placeholderHand('3-bet без позиции')],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final packs = _packsList;
    final categories = ['All', ...{for (final p in packs) p.category}];
    final visible = _selectedCategory == 'All'
        ? packs
        : packs.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировочные пакеты'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: _selectedCategory,
              dropdownColor: const Color(0xFF2A2B2E),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
              items: [
                for (final c in categories)
                  DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final pack = visible[index];
                return Card(
                  color: const Color(0xFF2A2B2E),
                  child: ListTile(
                    title: Text(pack.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(pack.description,
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3B3E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(pack.category,
                              style: const TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrainingPackScreen(pack: pack),
                        ),
                      );
                      if (updated is TrainingPack) {
                        final idx = _packsList.indexOf(pack);
                        if (idx != -1) {
                          setState(() => _packsList[idx] = updated);
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final pack = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePackScreen()),
          );
          if (pack is TrainingPack) {
            setState(() => _packsList.add(pack));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
