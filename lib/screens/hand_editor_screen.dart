import 'package:flutter/material.dart';
import '../widgets/poker_table_view.dart';

class HandEditorScreen extends StatelessWidget {
  const HandEditorScreen({super.key});

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
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  Center(child: Text('Coming soon')),
                  Center(child: Text('Coming soon')),
                  Center(child: Text('Coming soon')),
                  Center(child: Text('Coming soon')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
