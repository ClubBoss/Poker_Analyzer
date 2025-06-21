import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/player_zone_widget.dart';
import '../widgets/street_tabs.dart';
import '../widgets/street_action_list_simple.dart';
import '../models/card_model.dart';
import '../services/action_sync_service.dart';
import '../models/player_model.dart';

class PlayerZoneDemoScreen extends StatefulWidget {
  const PlayerZoneDemoScreen({super.key});

  @override
  State<PlayerZoneDemoScreen> createState() => _PlayerZoneDemoScreenState();
}

class _PlayerZoneDemoScreenState extends State<PlayerZoneDemoScreen> {
  int _street = 0;
  final List<String> _streetNames = const ['Preflop', 'Flop', 'Turn', 'River'];
  final List<PlayerModel> _players = [
    PlayerModel(name: 'Alice', stack: 100, bet: 0),
    PlayerModel(name: 'Bob', stack: 75, bet: 0),
    PlayerModel(name: 'Carol', stack: 200, bet: 0),
  ];
  final List<List<CardModel>> _cards = [[], [], []];

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
                final player = _players[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: PlayerZoneWidget(
                    player: player,
                    playerName: player.name,
                    street: _streetNames[_street],
                    position: null,
                    cards: _cards[index],
                    currentBet: player.bet,
                    stackSize: player.stack,
                    playerIndex: index,
                    remainingStack: player.stack,
                    isHero: index == 0,
                    isFolded: false,
                    editMode: true,
                    onStackChanged: (v) => setState(() => player.stack = v),
                    onBetChanged: (v) => setState(() => player.bet = v),
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
