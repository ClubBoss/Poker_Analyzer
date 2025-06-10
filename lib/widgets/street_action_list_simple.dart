import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/action_sync_service.dart';
import '../models/player_zone_action_entry.dart';

class StreetActionListSimple extends StatelessWidget {
  final String street;

  const StreetActionListSimple({super.key, required this.street});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ActionEntry>> actions =
        context.watch<ActionSyncService>().actions;
    final list = actions[street] ?? [];
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color _cardColor() => isDark ? Colors.grey[800]! : Colors.grey[100]!;
    Color _textColor() => isDark ? Colors.white : Colors.black87;

    String _iconForAction(String action) {
      switch (action) {
        case 'fold':
          return '❌';
        case 'bet':
          return '💰';
        case 'raise':
          return '⬆';
        case 'call':
          return '📞';
        default:
          return '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          street,
          style: TextStyle(
            color: _textColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              'No actions',
              style: TextStyle(color: _textColor().withOpacity(0.6)),
            ),
          )
        else
          for (final a in list)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Card(
                color: _cardColor(),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(_iconForAction(a.action)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${a.playerName}: ${a.action}${a.amount != null ? ' ${a.amount}' : ''}',
                          style: TextStyle(color: _textColor()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        Row(
          children: [
            TextButton(
              onPressed: () =>
                  context.read<ActionSyncService>().undoLastAction(street),
              child: const Text('Undo Last Action'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () =>
                  context.read<ActionSyncService>().clearStreet(street),
              child: const Text('Clear Street'),
            ),
          ],
        ),
      ],
    );
  }
}
