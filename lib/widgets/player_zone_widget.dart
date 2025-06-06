
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'card_selector.dart';

class PlayerZoneWidget extends StatelessWidget {
  final String playerName;
  final String? position;
  final List<CardModel> cards;
  final bool isHero;
  final bool isFolded;
  final bool isActive;
  final bool highlightLastAction;
  final bool showHint;
  final String? actionTagText;
  final Function(CardModel) onCardsSelected;
  final double scale;

  const PlayerZoneWidget({
    Key? key,
    required this.playerName,
    this.position,
    required this.cards,
    required this.isHero,
    required this.isFolded,
    required this.onCardsSelected,
    this.isActive = false,
    this.highlightLastAction = false,
    this.showHint = false,
    this.actionTagText,
    this.scale = 1.0,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final nameStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14 * scale,
    );
    final captionStyle = TextStyle(
      color: _getPositionColor(position),
      fontSize: 12 * scale,
      fontWeight: FontWeight.bold,
    );
    final tagStyle = TextStyle(color: Colors.white, fontSize: 12 * scale);

    final label = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 100 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playerName,
                  style: nameStyle,
                ),
                if (isHero)
                  Padding(
                    padding: EdgeInsets.only(left: 4.0 * scale),
                    child: Icon(
                      Icons.star,
                      color: Colors.orangeAccent,
                      size: 14 * scale,
                    ),
                  ),
              ],
            ),
            if (position != null)
              Padding(
                padding: EdgeInsets.only(top: 2.0 * scale),
                child: Text(
                  position!,
                  style: captionStyle,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );

    final labelWithIcon = Stack(
      clipBehavior: Clip.none,
      children: [
        label,
        Positioned(
          top: -4 * scale,
          right: -4 * scale,
          child: AnimatedOpacity(
            opacity: showHint ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: showHint ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 200),
              child: Tooltip(
                message: 'Нажмите, чтобы ввести действие',
                child: Icon(
                  Icons.edit,
                  size: 16 * scale,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        labelWithIcon,
        SizedBox(height: 4 * scale),
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
                width: 36 * scale,
                height: 52 * scale,
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
                          fontSize: 18 * scale,
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.grey),
              );
            }),
            ),
          ),
        ),
        if (actionTagText != null)
          Padding(
            padding: EdgeInsets.only(top: 4.0 * scale),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              child: Text(
                actionTagText!,
                style: tagStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );

    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        column,
      ],
    );

    Widget result = content;

    if (isFolded) {
      result = ClipRect(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Opacity(opacity: 0.6, child: result),
        ),
      );
    }

    result = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(2 * scale),
      decoration: (isActive || highlightLastAction)
          ? BoxDecoration(
              border: Border.all(color: Colors.blueAccent, width: 3),
              borderRadius: BorderRadius.circular(12 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.6),
                  blurRadius: 8,
                )
              ],
            )
          : null,
      child: result,
    );

    return result;
  }

  Color _getPositionColor(String? position) {
    switch (position) {
      case 'BTN':
        return Colors.amber;
      case 'SB':
      case 'BB':
        return Colors.blueAccent;
      default:
        return Colors.white70;
    }
  }
}
