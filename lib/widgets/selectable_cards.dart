// Обновлённый файл #5: selectable_cards.dart

import 'package:flutter/material.dart';
import '../models/card_model.dart';

class SelectableCards extends StatefulWidget {
  final List<CardModel> selectedCards;
  final Function(CardModel) onCardTap;

  const SelectableCards({
    Key? key,
    required this.selectedCards,
    required this.onCardTap,
  }) : super(key: key);

  @override
  State<SelectableCards> createState() => _SelectableCardsState();
}

class _SelectableCardsState extends State<SelectableCards> {
  String? selectedRank;
  String? selectedSuit;

  static const List<String> ranks = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'T',
    'J',
    'Q',
    'K',
    'A'
  ];
  static const List<String> suits = ['♠', '♥', '♦', '♣'];

  void addCard() {
    if (selectedRank != null && selectedSuit != null) {
      final newCard = CardModel(rank: selectedRank!, suit: selectedSuit!);
      if (!widget.selectedCards.contains(newCard) &&
          widget.selectedCards.length < 2) {
        widget.onCardTap(newCard);
      }
      setState(() {
        selectedRank = null;
        selectedSuit = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final alreadyTwoCards = widget.selectedCards.length >= 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedRank,
                  decoration: const InputDecoration(labelText: 'Ранг'),
                  items: ranks
                      .map((rank) => DropdownMenuItem(
                            value: rank,
                            child: Text(rank),
                          ))
                      .toList(),
                  onChanged: alreadyTwoCards
                      ? null
                      : (value) => setState(() => selectedRank = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedSuit,
                  decoration: const InputDecoration(labelText: 'Масть'),
                  items: suits
                      .map((suit) => DropdownMenuItem(
                            value: suit,
                            child: Text(suit),
                          ))
                      .toList(),
                  onChanged: alreadyTwoCards
                      ? null
                      : (value) => setState(() => selectedSuit = value),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: alreadyTwoCards ? null : addCard,
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('Добавить'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
