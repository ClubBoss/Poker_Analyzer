import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../poker_analyzer_screen.dart';

class EvaluationPanel extends StatelessWidget {
  const EvaluationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<PokerAnalyzerScreenState>();
    final results = s._queueService.completed;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Completed: ${results.length}', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        for (final r in results.take(20))
          Text('${r.playerIndex}: ${r.action}', style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

