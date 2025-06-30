import 'package:flutter/material.dart';
import '../widgets/poker_table_view.dart';
import '../widgets/card_picker_widget.dart';
import '../widgets/action_list_widget.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../helpers/poker_position_helper.dart';

class HandEditorScreen extends StatefulWidget {
  const HandEditorScreen({super.key});

  @override
  State<HandEditorScreen> createState() => _HandEditorScreenState();
}

class _HandEditorScreenState extends State<HandEditorScreen> {
  final List<CardModel> _heroCards = [];
  final List<CardModel> _boardCards = [];
  final int _playerCount = 6;
  int _heroIndex = 0;
  final List<String> _names = [];
  List<ActionEntry> _preflopActions = [
    ActionEntry(0, 0, 'post', amount: 1),
    ActionEntry(0, 1, 'post', amount: 2),
  ];
  List<ActionEntry> _flopActions = [];
  List<ActionEntry> _turnActions = [];
  List<ActionEntry> _riverActions = [];
  late List<double> _stacks;
  late List<PlayerAction> _actions;
  late List<double> _bets;
  double _pot = 0;

  @override
  void initState() {
    super.initState();
    _names.addAll(List.generate(_playerCount, (i) => 'Player ${i + 1}'));
    _stacks = List.filled(_playerCount, 100.0);
    _actions = List.filled(_playerCount, PlayerAction.none);
    _bets = List.filled(_playerCount, 0.0);
    _recompute();
  }

  void _recompute() {
    final stacks = List.filled(_playerCount, 100.0);
    final actions = List.filled(_playerCount, PlayerAction.none);
    final bets = List.filled(_playerCount, 0.0);
    double pot = 0;
    void apply(List<ActionEntry> list) {
      for (final a in list) {
        switch (a.action) {
          case 'fold':
            actions[a.playerIndex] = PlayerAction.fold;
            break;
          case 'post':
            final amt = (a.amount ?? 0).toDouble();
            stacks[a.playerIndex] -= amt;
            bets[a.playerIndex] = amt;
            pot += amt;
            actions[a.playerIndex] = PlayerAction.post;
            break;
          case 'call':
            final amt = (a.amount ?? 0).toDouble();
            final diff = amt - bets[a.playerIndex];
            if (diff > 0) {
              stacks[a.playerIndex] -= diff;
              pot += diff;
            }
            bets[a.playerIndex] = amt;
            actions[a.playerIndex] = PlayerAction.call;
            break;
          case 'raise':
            final amt = (a.amount ?? 0).toDouble();
            final diff = amt - bets[a.playerIndex];
            if (diff > 0) {
              stacks[a.playerIndex] -= diff;
              pot += diff;
            }
            bets[a.playerIndex] = amt;
            actions[a.playerIndex] = PlayerAction.raise;
            break;
          case 'push':
            final amt = (a.amount ?? 0).toDouble();
            final diff = amt - bets[a.playerIndex];
            if (diff > 0) {
              stacks[a.playerIndex] -= diff;
              pot += diff;
            }
            bets[a.playerIndex] = amt;
            actions[a.playerIndex] = PlayerAction.push;
            break;
        }
      }
    }

    for (final list in [
      _preflopActions,
      _flopActions,
      _turnActions,
      _riverActions
    ]) {
      apply(list);
    }

    setState(() {
      _stacks = stacks;
      _actions = actions;
      _bets = bets;
      _pot = pot;
    });
  }

  void _onPreflopChanged(List<ActionEntry> list) {
    setState(() {
      _preflopActions = list;
      _recompute();
    });
  }

  void _onFlopChanged(List<ActionEntry> list) {
    setState(() {
      _flopActions = list;
      _recompute();
    });
  }

  void _onTurnChanged(List<ActionEntry> list) {
    setState(() {
      _turnActions = list;
      _recompute();
    });
  }

  void _onRiverChanged(List<ActionEntry> list) {
    setState(() {
      _riverActions = list;
      _recompute();
    });
  }

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
            Padding(
              padding: const EdgeInsets.all(8),
              child: DropdownButton<int>(
                value: _heroIndex,
                underline: const SizedBox.shrink(),
                items: [
                  for (int i = 0; i < _playerCount; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(getPositionList(_playerCount)[i]),
                    )
                ],
                onChanged: (v) {
                  if (v == null) return;
                  _heroIndex = v;
                  _recompute();
                },
              ),
            ),
            IgnorePointer(
              child: PokerTableView(
                heroIndex: _heroIndex,
                playerCount: _playerCount,
                playerNames: _names,
                playerStacks: _stacks,
                playerActions: _actions,
                playerBets: _bets,
                onHeroSelected: (_) {},
                onStackChanged: (_, __) {},
                onNameChanged: (_, __) {},
                onBetChanged: (_, __) {},
                onActionChanged: (_, __) {},
                potSize: _pot,
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
                        const SizedBox(height: 12),
                        ActionListWidget(
                          playerCount: _playerCount,
                          initial: _preflopActions,
                          onChanged: _onPreflopChanged,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStreetPicker(0, 3),
                        const SizedBox(height: 12),
                        ActionListWidget(
                          playerCount: _playerCount,
                          initial: _flopActions,
                          onChanged: _onFlopChanged,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStreetPicker(3, 1),
                        const SizedBox(height: 12),
                        ActionListWidget(
                          playerCount: _playerCount,
                          initial: _turnActions,
                          onChanged: _onTurnChanged,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStreetPicker(4, 1),
                        const SizedBox(height: 12),
                        ActionListWidget(
                          playerCount: _playerCount,
                          initial: _riverActions,
                          onChanged: _onRiverChanged,
                        ),
                      ],
                    ),
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
