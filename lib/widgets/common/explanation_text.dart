import 'package:flutter/material.dart';

class ExplanationText extends StatelessWidget {
  final String selectedAction;
  final String correctAction;
  final String explanation;
  final String? category;
  final double? evLoss;

  const ExplanationText({
    super.key,
    required this.selectedAction,
    required this.correctAction,
    required this.explanation,
    this.category,
    this.evLoss,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = selectedAction == correctAction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Action: $selectedAction',
          style: const TextStyle(color: Colors.red),
        ),
        if (category != null) ...[
          const SizedBox(height: 8),
          Text(
            'Категория: $category',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (evLoss != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Утечка EV: -${evLoss!.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            ),
        ],
        const SizedBox(height: 4),
        Text(
          isCorrect ? '✅ Correct' : '❌ Mistake',
          style: TextStyle(color: isCorrect ? Colors.green : Colors.red),
        ),
        const SizedBox(height: 4),
        Text(
          'Correct Action: $correctAction',
          style: const TextStyle(color: Colors.green),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Explanation: ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: explanation,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
