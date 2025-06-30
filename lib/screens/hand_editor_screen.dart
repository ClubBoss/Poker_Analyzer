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
  final List<CardModel> _boardCards = [];

  Set<String> get _usedCards => {
        for (final c in _heroCards) '${c.rank}${c.suit}',
        for (final c in _boardCards) '${c.rank}${c.suit}',
      };

  void _setBoardCard(int index, CardModel card) {
    setState(() {
      if (_boardCards.length > index) {
        _boardCards[index] = card;
      } else if (_boardCards.length == index) {
        _boardCards.add(card);
      }
    });
  }

  Widget _buildBoardRow() {
    final cards =
        List.generate(5, (i) => i < _boardCards.length ? _boardCards[i] : null);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cards.map((c) {
          final isRed = c?.suit == '♥' || c?.suit == '♦';
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 36,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(c == null ? 0.3 : 1),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 3,
                  offset: const Offset(1, 2),
                )
              ],
            ),
            alignment: Alignment.center,
            child: c != null
                ? Text(
                    '${c.rank}${c.suit}',
                    style: TextStyle(
                      color: isRed ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : const Icon(Icons.add, color: Colors.grey),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStreetPicker(int start, int count) {
    final end = (_boardCards.length - start).clamp(0, count);
    final cards = end > 0
        ? _boardCards.sublist(start, start + end)
        : <CardModel>[];
    return CardPickerWidget(
      cards: cards,
      count: count,
      onChanged: (i, c) => _setBoardCard(start + i, c),
      disabledCards: _usedCards,
    );
  }

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
            _buildBoardRow(),
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
                          disabledCards: _usedCards,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStreetPicker(0, 3),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStreetPicker(3, 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStreetPicker(4, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
