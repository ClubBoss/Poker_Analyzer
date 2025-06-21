import 'package:flutter/material.dart';

import '../models/action_entry.dart';

class ResultScreen extends StatelessWidget {
  final int winnerIndex;
  final Map<int, int> winnings;
  final Map<int, int> finalStacks;
  final int potSize;
  final List<ActionEntry> actions;

  const ResultScreen({
    super.key,
    required this.winnerIndex,
    required this.winnings,
    required this.finalStacks,
    required this.potSize,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат раздачи'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              winnings.length > 1
                  ? 'Победители: ' +
                      winnings.entries
                          .map((e) => 'P${e.key + 1} (${e.value})')
                          .join(', ')
                  : 'Победитель: Игрок ${winnerIndex + 1}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text('Пот: $potSize',
                style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 16),
            const Text('Стек после раздачи:',
                style: TextStyle(fontSize: 16, color: Colors.white)),
            const SizedBox(height: 8),
            for (final entry in finalStacks.entries)
              Text('Игрок ${entry.key + 1}: ${entry.value}',
                  style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text('Действия:',
                style: TextStyle(fontSize: 16, color: Colors.white)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final a = actions[index];
                  return Text(
                    '${a.street}: P${a.playerIndex + 1} ${a.action} ${a.amount ?? ''}',
                    style: const TextStyle(color: Colors.white70),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF1B1C1E),
    );
  }
}
