import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../widgets/player_zone_widget.dart';
import '../widgets/street_actions_widget.dart';
import '../widgets/board_cards_widget.dart';
import '../widgets/street_actions_list.dart';
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
  final TextEditingController _commentController = TextEditingController();

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

  Future<void> _openActionDialog([int? playerIndex]) async {
    final entry = await showActionDialog(
      context,
      street: currentStreet,
      playerCount: numberOfPlayers,
      initialPlayer: playerIndex,
    );
    if (entry != null) {
      setState(() {
        actions.add(entry);
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
                  ...List.generate(numberOfPlayers, (i) {
                    final index = (i + heroIndex) % numberOfPlayers;
                    final angle = 2 * pi * (i - heroIndex) / numberOfPlayers + pi / 2;
                    final dx = radiusX * cos(angle);
                    final dy = radiusY * sin(angle);

                    return Positioned(
                      left: centerX + dx - 55,
                      top: centerY + dy - 55,
                      child: GestureDetector(
                        onTap: () => _openActionDialog(index),
                        child: PlayerZoneWidget(
                          playerName: 'Player ${index + 1}',
                          cards: playerCards[index],
                          isHero: index == heroIndex,
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
              child: StreetActionsList(
                street: currentStreet,
                actions: actions,
                onAdd: _openActionDialog,
              ),
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