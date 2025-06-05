// Файл: player_zone_widget.dart — обновлённая версия с плейсхолдерами для карт

import 'package:flutter/material.dart';
import '../models/card_model.dart';

class PlayerZoneWidget extends StatelessWidget {
  final String playerName;
  final List<CardModel> cards;
  final bool isHero;
  final Function(CardModel) onCardsSelected;

  const PlayerZoneWidget({
    Key? key,
    required this.playerName,
    required this.cards,
    required this.isHero,
    required this.onCardsSelected,
  }) : super(key: key);

  void _showCardSelector(BuildContext context) async {
    // Логика выбора карты
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCardSelector(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHero ? Colors.orange : Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isHero ? "$playerName (Hero)" : playerName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(2, (i) {
              if (i < cards.length) {
                final card = cards[i];
                return _buildCardBox(card.label, card.flutterColor);
              } else {
                return _buildCardBox('', Colors.grey.shade800);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBox(String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}