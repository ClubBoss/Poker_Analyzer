import 'package:flutter/material.dart';
import 'package:poker_analyzer/models/card_model.dart';
import '../theme/app_colors.dart';

class ImportMistake {
  final List<CardModel> cards;
  final String actual;
  final String expected;
  final double ev;
  final double icm;
  ImportMistake({
    required this.cards,
    required this.actual,
    required this.expected,
    required this.ev,
    required this.icm,
  });
}

class ImportSessionSummaryScreen extends StatelessWidget {
  final int total;
  final int correct;
  final List<ImportMistake> mistakes;
  const ImportSessionSummaryScreen({
    super.key,
    required this.total,
    required this.correct,
    required this.mistakes,
  });

  Widget _card(CardModel c) {
    final red = c.suit == '♥' || c.suit == '♦';
    return Container(
      width: 24,
      height: 34,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        '${c.rank}${c.suit}',
        style: TextStyle(
          color: red ? Colors.red : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = total == 0 ? 0 : correct * 100 / total;
    return Scaffold(
      appBar: AppBar(title: const Text('Session Summary')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hands: $total', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              'Accuracy: ${accuracy.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (mistakes.isNotEmpty) ...[
              const Text(
                'Biggest mistakes',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              for (final m in mistakes.take(5))
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _card(m.cards[0]),
                      _card(m.cards[1]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You: ${m.actual} • GTO: ${m.expected} • ${m.ev.toStringAsFixed(2)} / ${m.icm.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
