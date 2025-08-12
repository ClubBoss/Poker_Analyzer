import 'package:flutter/material.dart';
import '../models/card_model.dart';

Future<CardModel?> showCardSelector(BuildContext context,
    {Set<String> disabledCards = const {}}) async {
  final ranks = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];
  const suits = ['♠', '♥', '♦', '♣'];

  bool isDisabled(String rank, String suit) =>
      disabledCards.contains('$rank$suit');

  final selected = await showModalBottomSheet<CardModel>(
    context: context,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final r in ranks)
              for (final s in suits)
                GestureDetector(
                  onTap: isDisabled(r, s)
                      ? null
                      : () => Navigator.pop(ctx, CardModel(rank: r, suit: s)),
                  child: Opacity(
                    opacity: isDisabled(r, s) ? 0.4 : 1.0,
                    child: Container(
                      width: 36,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 3,
                            offset: const Offset(1, 2),
                          )
                        ],
                      ),
                      child: Text(
                        '$r$s',
                        style: TextStyle(
                          color: (s == '♥' || s == '♦')
                              ? Colors.red
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    ),
  );

  return selected;
}
