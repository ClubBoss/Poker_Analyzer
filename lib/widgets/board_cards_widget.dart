import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'card_selector.dart';

class BoardCardsWidget extends StatelessWidget {
  final int currentStreet;
  final List<CardModel> boardCards;
  final void Function(int, CardModel) onCardSelected;
  final void Function(int index)? onCardLongPress;
  final bool Function(int index)? canEditBoard;
  final Set<String> usedCards;
  final double scale;
  final List<Animation<double>>? revealAnimations;
  final bool editingDisabled;

  const BoardCardsWidget({
    Key? key,
    required this.currentStreet,
    required this.boardCards,
    required this.onCardSelected,
    this.onCardLongPress,
    this.canEditBoard,
    this.usedCards = const {},
    this.scale = 1.0,
    this.revealAnimations,
    this.editingDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visibleCount = [0, 3, 4, 5][currentStreet];

    final keyString = boardCards
        .take(visibleCount)
        .map((c) => '${c.rank}${c.suit}')
        .join('-');

    return Positioned.fill(
      child: Align(
        alignment: const Alignment(0, -0.05),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: Row(
            key: ValueKey('$keyString-$visibleCount'),
            mainAxisSize: MainAxisSize.min,
            children: List.generate(visibleCount, (index) {
              final card = index < boardCards.length ? boardCards[index] : null;
              final isRed = card?.suit == '♥' || card?.suit == '♦';

              final animation =
                  revealAnimations != null && index < revealAnimations!.length
                      ? revealAnimations![index]
                      : const AlwaysStoppedAnimation(1.0);
              return FadeTransition(
                opacity: animation,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: editingDisabled
                      ? null
                      : () async {
                          if (canEditBoard != null && !canEditBoard!(index))
                            return;
                          final disabled = Set<String>.from(usedCards);
                          if (card != null)
                            disabled.remove('${card.rank}${card.suit}');
                          final selected = await showCardSelector(context,
                              disabledCards: disabled);
                          if (selected != null) {
                            onCardSelected(index, selected);
                          }
                        },
                  onLongPress: editingDisabled
                      ? null
                      : () {
                          if (onCardLongPress != null &&
                              index < boardCards.length) {
                            onCardLongPress!(index);
                          }
                        },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 36 * scale,
                    height: 52 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: card == null ? 0.3 : 1),
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
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
