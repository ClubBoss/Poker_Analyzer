import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'card_selector.dart';

class BoardCardsWidget extends StatelessWidget {
  final int currentStreet;
  final List<CardModel> boardCards;
  final void Function(int, CardModel) onCardSelected;

  const BoardCardsWidget({
    Key? key,
    required this.currentStreet,
    required this.boardCards,
    required this.onCardSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visibleCount = [0, 3, 4, 5][currentStreet];

    return Positioned.fill(
      child: Align(
        alignment: const Alignment(0, -0.05),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(visibleCount, (index) {
            final card = index < boardCards.length ? boardCards[index] : null;
            final isRed = card?.suit == '♥' || card?.suit == '♦';

            return GestureDetector(
              onTap: () async {
                final selected = await showCardSelector(context);
                if (selected != null) {
                  onCardSelected(index, selected);
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 36,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(card == null ? 0.3 : 1),
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
                child: card != null
                    ? Text(
                        '${card.rank}${card.suit}',
                        style: TextStyle(
                          color: isRed ? Colors.red : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.grey),
              ),
            );
          }),
        ),
      ),
    );
  }
}
