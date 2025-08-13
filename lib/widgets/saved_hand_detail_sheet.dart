import 'package:flutter/material.dart';

import '../models/saved_hand.dart';

class SavedHandDetailSheet extends StatelessWidget {
  final SavedHand hand;
  final VoidCallback onDelete;
  final Future<void> Function() onExportJson;
  final Future<void> Function() onExportCsv;

  const SavedHandDetailSheet({
    super.key,
    required this.hand,
    required this.onDelete,
    required this.onExportJson,
    required this.onExportCsv,
  });

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d.$m.$y';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hand.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(hand.date),
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 8),
            if ([
              hand.tournamentId,
              hand.buyIn,
              hand.totalPrizePool,
              hand.numberOfEntrants,
              hand.gameType
            ].any((e) => e != null && e.toString().isNotEmpty)) ...[
              const Text('Tournament Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 4),
              if (hand.tournamentId != null && hand.tournamentId!.isNotEmpty)
                Text('ID: ${hand.tournamentId}',
                    style: const TextStyle(color: Colors.white70)),
              if (hand.buyIn != null)
                Text('Buy-In: ${hand.buyIn}',
                    style: const TextStyle(color: Colors.white70)),
              if (hand.totalPrizePool != null)
                Text('Prize Pool: ${hand.totalPrizePool}',
                    style: const TextStyle(color: Colors.white70)),
              if (hand.numberOfEntrants != null)
                Text('Entrants: ${hand.numberOfEntrants}',
                    style: const TextStyle(color: Colors.white70)),
              if (hand.gameType != null && hand.gameType!.isNotEmpty)
                Text('Game: ${hand.gameType}',
                    style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
            ],
            Text('Позиция: ${hand.heroPosition}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Стек: ${hand.stackSizes[hand.heroIndex] ?? '-'}',
                style: const TextStyle(color: Colors.white70)),
            if (hand.comment != null) ...[
              const SizedBox(height: 12),
              const Text('Комментарий:', style: TextStyle(color: Colors.white)),
              Text(hand.comment!,
                  style: const TextStyle(color: Colors.white70)),
            ],
            if (hand.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in hand.tags)
                    Chip(
                      label: Text(t),
                      backgroundColor: const Color(0xFF3A3B3E),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ],
            if (hand.actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Действия:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              for (final a in hand.actions)
                Text(
                  'S${a.street}: P${a.playerIndex} ${a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action}${a.amount != null ? ' • ${a.amount}' : ''}',
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onExportJson,
                  child: const Text('Экспорт JSON'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onExportCsv,
                  child: const Text('Экспорт CSV'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
