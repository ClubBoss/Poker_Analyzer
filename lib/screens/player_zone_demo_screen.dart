import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/player_zone_widget.dart';
import '../widgets/street_tabs.dart';
import '../widgets/street_action_list_simple.dart';
import '../models/card_model.dart';
import '../services/action_sync_service.dart';

class PlayerZoneDemoScreen extends StatefulWidget {
  const PlayerZoneDemoScreen({super.key});

  @override
  State<PlayerZoneDemoScreen> createState() => _PlayerZoneDemoScreenState();
}

class _PlayerZoneDemoScreenState extends State<PlayerZoneDemoScreen> {
  int _street = 0;
  final List<String> _streetNames = const ['Preflop', 'Flop', 'Turn', 'River'];
  final List<String> _players = const ['Alice', 'Bob', 'Carol'];
  final List<List<CardModel>> _cards = [[], [], []];
  final List<int> _stacks = const [100, 75, 200];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player Zone Demo')),
      body: Column(
        children: [
          StreetTabs(
            currentStreet: _street,
            onStreetChanged: (i) => setState(() => _street = i),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _players.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: PlayerZoneWidget(
                    playerName: _players[index],
                    street: _streetNames[_street],
                    position: null,
                    cards: _cards[index],
                    stackSize: _stacks[index],
                    isHero: index == 0,
                    isFolded: false,
                    onCardsSelected: (i, c) {},
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in _streetNames)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: StreetActionListSimple(street: s),
                    ),
                  TextButton(
                    onPressed: () =>
                        context.read<ActionSyncService>().undoLastGlobal(),
                    child: const Text('Undo Global'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
