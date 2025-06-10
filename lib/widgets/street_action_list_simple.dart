import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/action_sync_service.dart';
import '../models/player_zone_action_entry.dart';

class StreetActionListSimple extends StatefulWidget {
  final String street;

  const StreetActionListSimple({super.key, required this.street});

  @override
  State<StreetActionListSimple> createState() => _StreetActionListSimpleState();
}

class _StreetActionListSimpleState extends State<StreetActionListSimple> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ActionEntry>> actions =
        context.watch<ActionSyncService>().actions;
    final list = actions[widget.street] ?? [];
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
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? '▼' : '▶',
                style: TextStyle(color: _textColor()),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.street,
              style: TextStyle(
                color: _textColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (_expanded) ...[
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
                    context.read<ActionSyncService>().undoLastAction(widget.street),
                child: const Text('Undo Last Action'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () =>
                    context.read<ActionSyncService>().clearStreet(widget.street),
                child: const Text('Clear Street'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
