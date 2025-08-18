import 'package:flutter/material.dart';

import '../models/action_entry.dart';
import '../widgets/sync_status_widget.dart';

class ResultScreen extends StatelessWidget {
  final int winnerIndex;
  final Map<int, int> winnings;
  final Map<int, int> finalStacks;
  final int potSize;
  final List<int> sidePots;
  final List<ActionEntry> actions;

  const ResultScreen({
    super.key,
    required this.winnerIndex,
    required this.winnings,
    required this.finalStacks,
    required this.potSize,
    required this.sidePots,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат раздачи'),
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              winnings.length > 1
                  ? 'Победители: ${winnings.entries.map((e) => 'P${e.key + 1} (${e.value})').join(', ')}'
                  : 'Победитель: Игрок ${winnerIndex + 1}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            _PotBreakdown(
              potSize: potSize,
              sidePots: sidePots,
              winnings: winnings,
            ),
            const SizedBox(height: 8),
            Text(
              'Пот: $potSize',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Стек после раздачи:',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 8),
            for (final entry in finalStacks.entries)
              Text(
                'Игрок ${entry.key + 1}: ${entry.value}',
                style: const TextStyle(color: Colors.white70),
              ),
            const SizedBox(height: 16),
            const Text(
              'Действия:',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
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

class _PotBreakdown extends StatelessWidget {
  final int potSize;
  final List<int> sidePots;
  final Map<int, int> winnings;

  const _PotBreakdown({
    required this.potSize,
    required this.sidePots,
    required this.winnings,
  });

  @override
  Widget build(BuildContext context) {
    final mainPot = potSize - sidePots.fold<int>(0, (p, e) => p + e);
    final pots = <int>[mainPot, ...sidePots];
    final names = <String>['Main Pot'];
    names.addAll(List.generate(sidePots.length, (i) => 'Side Pot ${i + 1}'));
    final totalWin = winnings.values.fold<int>(0, (p, e) => p + e);

    final lines = <Widget>[];
    for (int i = 0; i < pots.length; i++) {
      final potAmount = pots[i];
      if (potAmount <= 0) continue;
      final shares = <int, int>{};
      winnings.forEach((player, amount) {
        final share = (potAmount * (amount / (totalWin == 0 ? 1 : totalWin)))
            .round();
        if (share > 0) shares[player] = share;
      });
      final winnersText = shares.entries
          .map((e) => 'P${e.key + 1} wins ${e.value}')
          .join(', ');
      lines.add(
        Text(
          '${names[i]} → $winnersText',
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
      );
    }

    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pot Breakdown:',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 4),
        ...lines,
      ],
    );
  }
}
