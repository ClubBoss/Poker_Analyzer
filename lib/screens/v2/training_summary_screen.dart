import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:poker_analyzer/l10n/app_localizations.dart';

class TrainingSummaryScreen extends StatelessWidget {
  final int correct;
  final int total;
  final int fixedCount;
  final int remainingMistakeCount;
  const TrainingSummaryScreen({
    super.key,
    required this.correct,
    required this.total,
    required this.fixedCount,
    required this.remainingMistakeCount,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rate = total == 0 ? 0 : correct * 100 / total;
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Correct $correct / $total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: ${rate.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Fixed Mistakes: $fixedCount',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Remaining Mistakes: $remainingMistakeCount',
              style: const TextStyle(color: Colors.white70),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.reviewMistakes),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Exit'),
            ),
          ],
        ),
      ),
    );
  }
}
