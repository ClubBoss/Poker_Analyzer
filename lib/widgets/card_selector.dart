import 'package:flutter/material.dart';
import '../models/card_model.dart';

Future<CardModel?> showCardSelector(BuildContext context) async {
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

  if (selectedRank == null) return null;

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
    return CardModel(rank: selectedRank!, suit: selectedSuit!);
  }
  return null;
}
