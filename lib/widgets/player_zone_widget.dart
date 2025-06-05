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

  Future<void> _showCardSelector(BuildContext context) async {
    final ranks = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];
    const suits = ['♠', '♥', '♦', '♣'];

    String? selectedRank;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выберите ранг', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: ranks
                  .map(
                    (r) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () {
                        selectedRank = r;
                        Navigator.pop(ctx);
                      },
                      child: Text(r),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );

    if (selectedRank == null) return;

    String? selectedSuit;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выберите масть', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: suits
                  .map(
                    (s) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        selectedSuit = s;
                        Navigator.pop(ctx);
                      },
                      child: Text(s, style: const TextStyle(fontSize: 24)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );

    if (selectedRank != null && selectedSuit != null) {
      onCardsSelected(CardModel(rank: selectedRank!, suit: selectedSuit!));
    }
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
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(
    2,
    (index) {
      final card = index < cards.length ? cards[index] : null;
      final isRed = card?.suit == '♥' || card?.suit == '♦';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 36,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
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
    },
  ),
)
        ],
      ),
    );
  }
}