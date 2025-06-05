// Файл: poker_analyzer_screen.dart — Обновлённая версия с сохранением Hero снизу

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../widgets/player_zone_widget.dart';
import '../widgets/street_actions_widget.dart';

class PokerAnalyzerScreen extends StatefulWidget {
  const PokerAnalyzerScreen({super.key});

  @override
  State<PokerAnalyzerScreen> createState() => _PokerAnalyzerScreenState();
}

class _PokerAnalyzerScreenState extends State<PokerAnalyzerScreen> {
  int heroIndex = 0;
  int numberOfPlayers = 6;
  List<List<CardModel>> playerCards = List.generate(9, (_) => []);
  int currentStreet = 0;
  final TextEditingController _commentController = TextEditingController();

  void selectCard(int index, CardModel card) {
    setState(() {
      if (playerCards[index].length < 2) {
        playerCards[index].add(card);
      }
    });
  }

  void _openActionDialog(int playerIndex) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Действие игрока ${playerIndex + 1}'),
        content: const Text('Здесь будет интерфейс выбора действия.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final radius = screenSize.width / 2.6;
    final centerX = screenSize.width / 2;
    final tableHeight = screenSize.width * 0.55;
    final centerY = (screenSize.width - tableHeight) / 2 + tableHeight / 2;

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
                      width: screenSize.width * 0.9,
                      fit: BoxFit.contain,
                    ),
                  ),
                  ...List.generate(numberOfPlayers, (i) {
                    final index = (i + heroIndex) % numberOfPlayers;
                    final angle = 2 * pi * (i - heroIndex) / numberOfPlayers + pi / 2;
                    final dx = radius * cos(angle);
                    final dy = radius * sin(angle);

                    return Positioned(
                      left: centerX + dx - 60,
                      top: centerY + dy - 60,
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
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Комментарий к раздаче',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Анализировать раздачу'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}