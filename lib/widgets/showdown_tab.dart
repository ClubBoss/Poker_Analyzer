import 'package:flutter/material.dart';
import '../models/card_model.dart';

class ShowdownTab extends StatelessWidget {
  final List<String> names;
  final List<List<CardModel>> revealed;
  final List<double> stacks;
  final List<double> winnings;
  final List<List<double>> parts;
  final double pot;
  const ShowdownTab({
    super.key,
    required this.names,
    required this.revealed,
    required this.stacks,
    required this.winnings,
    required this.parts,
    required this.pot,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revealed cards:', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          ...List.generate(names.length, (i) {
            final cards = i < revealed.length ? revealed[i] : <CardModel>[];
            final text = cards.isEmpty
                ? '—'
                : cards.map((c) => '${c.rank}${c.suit}').join(' ');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('Player ${i + 1} – $text',
                  style: const TextStyle(color: Colors.white70)),
            );
          }),
          const SizedBox(height: 16),
          const Text('Result:', style: TextStyle(color: Colors.white)),
          if (pot > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Unclaimed pot: ${pot.toStringAsFixed(1)} BB',
                  style: const TextStyle(color: Colors.white38)),
            ),
          const SizedBox(height: 8),
          ...List.generate(names.length, (i) {
            final before = stacks[i] - winnings[i];
            final after = stacks[i];
            final win = winnings[i];
            final partsText = parts[i].isNotEmpty
                ? ' = ${List.generate(parts[i].length, (j) {
                    final label = j == 0 ? 'main' : 'side';
                    return '${parts[i][j].toStringAsFixed(1)} $label';
                  }).join(' + ')}'
                : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                'Player ${i + 1}: ${before.toStringAsFixed(1)} ⇒ ${after.toStringAsFixed(1)}${win > 0 ? ' (+${win.toStringAsFixed(1)}$partsText)' : ''}',
                style: TextStyle(
                  color: Colors.white70,
                  decoration: win > 0 ? TextDecoration.underline : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
