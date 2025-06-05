import 'package:flutter/material.dart';

class BoardCardsWidget extends StatelessWidget {
  final List<String> boardCards;

  const BoardCardsWidget({super.key, required this.boardCards});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 135, // Поднять выше относительно центра
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: boardCards.map((cardPath) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Image.asset(cardPath, width: 36),
          );
        }).toList(),
      ),
    );
  }
}