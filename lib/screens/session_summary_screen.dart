import 'package:flutter/material.dart';

class SessionSummaryScreen extends StatelessWidget {
  final int total;
  final int correct;
  const SessionSummaryScreen(
      {super.key, required this.total, required this.correct});

  @override
  Widget build(BuildContext context) {
    final accuracy = total == 0 ? 0 : correct * 100 / total;
    return Scaffold(
      appBar: AppBar(title: const Text('Session Summary')),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$correct / $total',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Accuracy: ${accuracy.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
