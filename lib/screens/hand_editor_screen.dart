import 'package:flutter/material.dart';
import '../widgets/poker_table_view.dart';
import '../widgets/card_picker_widget.dart';
import '../models/card_model.dart';

class HandEditorScreen extends StatefulWidget {
  const HandEditorScreen({super.key});

  @override
  State<HandEditorScreen> createState() => _HandEditorScreenState();
}

class _HandEditorScreenState extends State<HandEditorScreen> {
  final List<CardModel> _heroCards = [];

  @override
  Widget build(BuildContext context) {
    final names = List.generate(6, (i) => 'Player ${i + 1}');
    final stacks = List.filled(6, 0.0);
    final actions = List.filled(6, PlayerAction.none);
    final bets = List.filled(6, 0.0);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hand Editor'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Preflop'),
              Tab(text: 'Flop'),
              Tab(text: 'Turn'),
              Tab(text: 'River'),
            ],
          ),
        ),
        body: Column(
          children: [
            IgnorePointer(
              child: PokerTableView(
                heroIndex: 0,
                playerCount: 6,
                playerNames: names,
                playerStacks: stacks,
                playerActions: actions,
                playerBets: bets,
                onHeroSelected: (_) {},
                onStackChanged: (_, __) {},
                onNameChanged: (_, __) {},
                onBetChanged: (_, __) {},
                onActionChanged: (_, __) {},
                potSize: 0,
                onPotChanged: (_) {},
                heroCards: _heroCards,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CardPickerWidget(
                          cards: _heroCards,
                          onChanged: (i, c) {
                            setState(() {
                              if (_heroCards.length > i) {
                                _heroCards[i] = c;
                              } else {
                                _heroCards.add(c);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Center(child: Text('Coming soon')),
                  const Center(child: Text('Coming soon')),
                  const Center(child: Text('Coming soon')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
