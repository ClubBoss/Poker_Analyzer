import 'package:flutter/material.dart';

/// Displays a progress bar indicating how much of the hand setup is complete.
class HandCompletionIndicator extends StatelessWidget {
  /// Progress value between 0 and 1.
  final double progress;

  const HandCompletionIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.secondary,
          ),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(
          'Заполнение: $percent%',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
