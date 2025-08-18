import 'package:flutter/material.dart';
import '../models/card_model.dart';

class PlayingCardWidget extends StatelessWidget {
  final CardModel card;
  final double scale;
  const PlayingCardWidget({Key? key, required this.card, this.scale = 1.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isRed = card.suit == '♥' || card.suit == '♦';
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2 * scale),
      width: 18 * scale,
      height: 26 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '${card.rank}${card.suit}',
        style: TextStyle(
          color: isRed ? Colors.red : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12 * scale,
        ),
      ),
    );
  }
}
