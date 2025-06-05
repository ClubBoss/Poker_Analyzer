
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'card_selector.dart';

class PlayerZoneWidget extends StatelessWidget {
  final String playerName;
  final List<CardModel> cards;
  final bool isHero;
  final bool isFolded;
  final bool isActive;
  final bool showHint;
  final String? lastActionText;
  final Function(CardModel) onCardsSelected;

  const PlayerZoneWidget({
    Key? key,
    required this.playerName,
    required this.cards,
    required this.isHero,
    required this.isFolded,
    required this.onCardsSelected,
    this.isActive = false,
    this.showHint = false,
    this.lastActionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
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
            if (showHint)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Tooltip(
                  message: 'Нажмите, чтобы ввести действие',
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final card = await showCardSelector(context);
            if (card != null) {
              onCardsSelected(card);
            }
          },
          child: Opacity(
            opacity: isFolded ? 0.4 : 1.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
              final card = index < cards.length ? cards[index] : null;
              final isRed = card?.suit == '♥' || card?.suit == '♦';

              return Container(
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
              );
            }),
            ),
          ),
        ),
        if (lastActionText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              lastActionText!,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
      ],
    );

    Widget result = content;

    if (isFolded) {
      result = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: Opacity(opacity: 0.6, child: result),
      );
    }

    result = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(2),
      decoration: isActive
          ? BoxDecoration(
              border: Border.all(color: Colors.amberAccent, width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.amberAccent.withOpacity(0.6),
                  blurRadius: 8,
                )
              ],
            )
          : null,
      child: result,
    );

    return result;
  }
}
