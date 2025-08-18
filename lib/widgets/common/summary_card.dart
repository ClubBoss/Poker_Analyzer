import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SummaryCard extends StatelessWidget {
  final int correctCount;
  final int totalAnswered;
  final String message;
  final VoidCallback onRetry;

  const SummaryCard({
    super.key,
    required this.correctCount,
    required this.totalAnswered,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Summary',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              'Correct: $correctCount / $totalAnswered',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
