import 'dart:math';
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
  int heroIndex = 0;
  int numberOfPlayers = 6;
  List<List<CardModel>> playerCards = List.generate(9, (_) => []);
  List<CardModel> boardCards = [];
  int currentStreet = 0;
  List<ActionEntry> actions = [];
  List<int> _pots = List.filled(4, 0);
  final TextEditingController _commentController = TextEditingController();
  List<bool> _showActionHints = List.filled(9, true);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showActionHints = List.filled(9, false);
        });
      }
    });
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

  String? _getLastActionText(int playerIndex) {
    final entries = actions.where((a) =>
        a.playerIndex == playerIndex && a.street == currentStreet);
    if (entries.isEmpty) return null;
    final last = entries.last;
    final amountStr = last.amount != null ? ' ${last.amount}' : '';
    return '${last.action}$amountStr';
  }

  Future<void> _openActionDialog(int playerIndex) async {
    setState(() {
      _showActionHints[playerIndex] = false;
    });
    final entry = await showActionDialog(
      context,
      street: currentStreet,
      playerIndex: playerIndex,
      callAmount: _calculateCallAmount(playerIndex),
      hasBet: _streetHasBet(),
      currentPot: _pots[currentStreet],
    );
    if (entry != null) {
      setState(() {
        actions.add(entry);
        _recalculatePots();
      });
    }
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
                  });
                }
              },
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
                  Positioned.fill(
                    child: Align(
                      alignment: const Alignment(0, -0.4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pot: ${_pots[currentStreet]}',
                          style: const TextStyle(color: Colors.white),
                        ),
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
                    final lastActionText = _getLastActionText(index);

                    return Positioned(
                      left: centerX + dx - 55,
                      top: centerY + dy - 55,
                      child: GestureDetector(
                        onTap: () => _openActionDialog(index),
                        child: PlayerZoneWidget(
                          playerName: 'Player ${index + 1}',
                          cards: playerCards[index],
                          isHero: index == heroIndex,
                          isFolded: isFolded,
                          showHint: _showActionHints[index],
                          lastActionText: lastActionText,
                          onCardsSelected: (card) => selectCard(index, card),
                        ),
                      ),
                    );
                  })
                ],
              ),
            ),
            StreetActionsWidget(
              currentStreet: currentStreet,
              onStreetChanged: (index) => setState(() => currentStreet = index),
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