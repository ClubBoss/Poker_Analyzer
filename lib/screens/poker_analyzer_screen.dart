import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../widgets/player_zone_widget.dart';
import '../widgets/street_actions_widget.dart';
import '../widgets/board_cards_widget.dart';
import '../widgets/action_dialog.dart';

class PokerAnalyzerScreen extends StatefulWidget {
  const PokerAnalyzerScreen({super.key});

  @override
  State<PokerAnalyzerScreen> createState() => _PokerAnalyzerScreenState();
}

class _PokerAnalyzerScreenState extends State<PokerAnalyzerScreen> {
  final int heroIndex = 0;
  String _heroPosition = 'BTN';
  int numberOfPlayers = 6;
  final List<List<CardModel>> playerCards = List.generate(9, (_) => []);
  final List<CardModel> boardCards = [];
  int currentStreet = 0;
  final List<ActionEntry> actions = [];
  final List<int> _pots = List.filled(4, 0);
  final Map<int, int> _streetInvestments = {};
  final Map<int, int> stackSizes = {
    0: 120,
    1: 80,
    2: 100,
    3: 90,
    4: 110,
    5: 70,
    6: 130,
    7: 95,
    8: 105,
  };
  final TextEditingController _commentController = TextEditingController();
  final List<bool> _showActionHints = List.filled(9, true);
  final Set<int> _firstActionTaken = {};
  int? activePlayerIndex;
  Timer? _activeTimer;
  final Map<int, String?> _actionTags = {};
  Map<int, String> playerPositions = {};

  List<String> _positionsForPlayers(int count) {
    const base = ['BTN', 'SB', 'BB', 'UTG', 'LJ', 'HJ', 'CO'];
    if (count <= base.length) {
      return base.sublist(0, count);
    }
    final result = List<String>.from(base);
    for (int i = base.length; i < count; i++) {
      result.add('UTG+${i - 3}');
    }
    return result;
  }

  void setPosition(int playerIndex, String position) {
    setState(() {
      playerPositions[playerIndex] = position;
    });
  }

  void _updatePositions() {
    final order = _positionsForPlayers(numberOfPlayers);
    final heroPosIndex = order.indexOf(_heroPosition);
    final buttonIndex =
        (heroIndex - heroPosIndex + numberOfPlayers) % numberOfPlayers;
    playerPositions = {};
    for (int i = 0; i < numberOfPlayers; i++) {
      final posIndex = (i - buttonIndex + numberOfPlayers) % numberOfPlayers;
      if (posIndex < order.length) {
        playerPositions[i] = order[posIndex];
      }
    }
  }

  Future<void> _chooseHeroPosition() async {
    final options = _positionsForPlayers(numberOfPlayers);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выбрать позицию Hero'),
        children: [
          for (final pos in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, pos),
              child: Text(pos),
            ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _heroPosition = result;
        _updatePositions();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _updatePositions();
  }

  void selectCard(int index, CardModel card) {
    setState(() {
      for (final cards in playerCards) {
        cards.removeWhere((c) => c == card);
      }
      boardCards.removeWhere((c) => c == card);
      if (playerCards[index].length < 2) {
        playerCards[index].add(card);
      }
    });
  }

  void selectBoardCard(int index, CardModel card) {
    setState(() {
      for (final cards in playerCards) {
        cards.removeWhere((c) => c == card);
      }
      boardCards.removeWhere((c) => c == card);
      if (index < boardCards.length) {
        boardCards[index] = card;
      } else if (index == boardCards.length) {
        boardCards.add(card);
      }
    });
  }

  int _calculateCallAmount(int playerIndex) {
    final streetActions =
        actions.where((a) => a.street == currentStreet).toList();
    final Map<int, int> bets = {};
    int highest = 0;
    for (final a in streetActions) {
      if (a.action == 'bet' || a.action == 'raise' || a.action == 'call') {
        bets[a.playerIndex] = (bets[a.playerIndex] ?? 0) + (a.amount ?? 0);
        highest = max(highest, bets[a.playerIndex]!);
      }
    }
    final playerBet = bets[playerIndex] ?? 0;
    return max(0, highest - playerBet);
  }

  bool _streetHasBet() {
    return actions
        .where((a) => a.street == currentStreet)
        .any((a) => a.action == 'bet' || a.action == 'raise');
  }

  int _calculatePotForStreet(int street) {
    int pot = 0;
    for (int s = 0; s <= street; s++) {
      pot += actions
          .where((a) => a.street == s &&
              (a.action == 'call' || a.action == 'bet' || a.action == 'raise'))
          .fold<int>(0, (sum, a) => sum + (a.amount ?? 0));
    }
    return pot;
  }

  void _recalculatePots() {
    int cumulative = 0;
    for (int s = 0; s < _pots.length; s++) {
      final streetAmount = actions
          .where((a) => a.street == s &&
              (a.action == 'call' || a.action == 'bet' || a.action == 'raise'))
          .fold<int>(0, (sum, a) => sum + (a.amount ?? 0));
      cumulative += streetAmount;
      _pots[s] = cumulative;
    }
  }

  void _recalculateStreetInvestments() {
    _streetInvestments.clear();
    for (final a in actions.where((a) => a.street == currentStreet)) {
      if (a.action == 'call' || a.action == 'bet' || a.action == 'raise') {
        _streetInvestments[a.playerIndex] =
            (_streetInvestments[a.playerIndex] ?? 0) + (a.amount ?? 0);
      } else if (a.action == 'fold') {
        _streetInvestments.remove(a.playerIndex);
      }
    }
  }

  void onActionSelected(ActionEntry entry) {
    setState(() {
      actions.add(entry);
      _pots[currentStreet] = _calculatePotForStreet(currentStreet);
      _recalculateStreetInvestments();
    });
  }



  @override
  void dispose() {
    _activeTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - 120;
    final radiusX = tableWidth / 2 - 50;
    final radiusY = tableHeight / 2 + 100;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            DropdownButton<int>(
              value: numberOfPlayers,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              items: [
                for (int i = 2; i <= 9; i++)
                  DropdownMenuItem(value: i, child: Text('Игроков: $i')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    numberOfPlayers = value;
                    _updatePositions();
                  });
                }
              },
            ),
            TextButton(
              onPressed: _chooseHeroPosition,
              child: const Text('Выбрать позицию Hero'),
            ),
            Expanded(
              flex: 7,
              child: Stack(
                children: [
                  Center(
                    child: Image.asset(
                      'assets/table.png',
                      width: tableWidth,
                      fit: BoxFit.contain,
                    ),
                  ),
                  BoardCardsWidget(
                    currentStreet: currentStreet,
                    boardCards: boardCards,
                    onCardSelected: selectBoardCard,
                  ),
                  Positioned(
                    left: centerX - 40,
                    top: centerY - 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pot: \$${_pots[currentStreet]}',
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                  ...List.generate(numberOfPlayers, (i) {
                    final index = (i + heroIndex) % numberOfPlayers;
                    final angle =
                        2 * pi * (i - heroIndex) / numberOfPlayers + pi / 2;
                    final dx = radiusX * cos(angle);
                    final dy = radiusY * sin(angle);

                    final isFolded = actions.any((a) =>
                        a.playerIndex == index &&
                        a.action == 'fold' &&
                        a.street <= currentStreet);
                    final actionTag = _actionTags[index];

                    ActionEntry? lastAction;
                    for (final a in actions.reversed) {
                      if (a.playerIndex == index && a.street == currentStreet) {
                        lastAction = a;
                        break;
                      }
                    }

                    return [
                      Positioned(
                        left: centerX + dx - 55,
                        top: centerY + dy - 55,
                        child: GestureDetector(
                          onTap: () async {
                            setState(() {
                              activePlayerIndex = index;
                            });
                            final result = await showDialog<ActionEntry>(
                              context: context,
                              builder: (context) => ActionDialog(
                                playerIndex: index,
                                street: currentStreet,
                                pot: _pots[currentStreet],
                                stackSize: stackSizes[index] ?? 0,
                              ),
                            );
                            if (result != null) {
                              onActionSelected(result);
                            }
                            setState(() {
                              if (activePlayerIndex == index) {
                                activePlayerIndex = null;
                              }
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PlayerZoneWidget(
                                playerName: 'Player ${index + 1}',
                                cards: playerCards[index],
                                isHero: index == heroIndex,
                                isFolded: isFolded,
                                isActive: index == activePlayerIndex,
                                showHint: _showActionHints[index],
                                actionTagText: actionTag,
                                chipAmount: _streetInvestments[index],
                                stackSize: stackSizes[index],
                                onCardsSelected: (card) => selectCard(index, card),
                              ),
                              if (playerPositions[index] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    playerPositions[index]!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Stack: \$${stackSizes[index] ?? 0}',
                                  style: TextStyle(
                                    color: isFolded ? Colors.white38 : Colors.white,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              ],
                            ),
                          ),
                      ),
                      if (lastAction != null)
                        Positioned(
                          left: centerX + dx - 30,
                          top: centerY + dy + 60,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${lastAction!.action}${lastAction!.amount != null ? ' ${lastAction!.amount}' : ''}',
                              style:
                                  const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      if (lastAction != null &&
                          (lastAction!.action == 'bet' ||
                              lastAction!.action == 'raise' ||
                              lastAction!.action == 'call') &&
                          lastAction!.amount != null)
                        Positioned(
                          left: centerX + dx - 20,
                          top: centerY + dy + 80,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              '${lastAction!.amount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      if (_streetInvestments[index] != null &&
                          _streetInvestments[index]! > 0)
                        Positioned(
                          left: centerX + dx - 25,
                          top: centerY + dy + 85,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.black54, Colors.black87],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '\$${_streetInvestments[index]}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ];
                  }).expand((w) => w)
                ],
              ),
            ),
            StreetActionsWidget(
              currentStreet: currentStreet,
              onStreetChanged: (index) {
                setState(() {
                  currentStreet = index;
                  _pots[currentStreet] = _calculatePotForStreet(currentStreet);
                  _recalculateStreetInvestments();
                  _actionTags.clear();
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Комментарий к раздаче',
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
