import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'card_selector.dart';

class CardPickerWidget extends StatelessWidget {
  final List<CardModel> cards;
  final void Function(int, CardModel) onChanged;
  final double scale;
  final int count;
  final Set<String> disabledCards;
  const CardPickerWidget({
    super.key,
    required this.cards,
    required this.onChanged,
    this.scale = 1,
    this.count = 2,
    this.disabledCards = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final card = i < cards.length ? cards[i] : null;
        final isRed = card?.suit == '♥' || card?.suit == '♦';
        return GestureDetector(
          onTap: () async {
            final disabled = {
              ...disabledCards,
              for (final c in cards) '${c.rank}${c.suit}'
            };
            if (card != null) disabled.remove('${card.rank}${card.suit}');
            final selected =
                await showCardSelector(context, disabledCards: disabled);
            if (selected != null) onChanged(i, selected);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 36 * scale,
            height: 52 * scale,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: card == null ? 0.3 : 1),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
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
                      fontSize: 18 * scale,
                    ),
                  )
                : const Icon(Icons.add, color: Colors.grey),
          ),
        );
      }),
    );
  }
}
