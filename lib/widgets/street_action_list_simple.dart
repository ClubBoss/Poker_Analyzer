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

  Future<void> _editAction(int index, ActionEntry entry) async {
    final controller = TextEditingController(
      text: entry.amount?.toString() ?? '',
    );
    String action = entry.action;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final needAmount = action == 'bet' || action == 'raise';
          return Padding(
            padding: MediaQuery.of(ctx).viewInsets + const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButton<String>(
                  value: action,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'fold', child: Text('Fold')),
                    DropdownMenuItem(value: 'call', child: Text('Call')),
                    DropdownMenuItem(value: 'bet', child: Text('Bet')),
                    DropdownMenuItem(value: 'raise', child: Text('Raise')),
                  ],
                  onChanged: (val) => setModal(() => action = val ?? action),
                ),
                if (needAmount) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx, {
                      'action': action,
                      'amount':
                          needAmount ? int.tryParse(controller.text) : null,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (result != null) {
      final newEntry = ActionEntry(
        playerName: entry.playerName,
        street: entry.street,
        action: result['action'] as String,
        amount: result['amount'] as int?,
      );
      context
          .read<ActionSyncService>()
          .updateAction(widget.street, index, newEntry);
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ActionEntry>> actions =
        context.watch<ActionSyncService>().actions;
    final list = actions[widget.street] ?? [];
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color cardColor() => isDark ? Colors.grey[800]! : Colors.grey[100]!;
    Color textColor() => isDark ? Colors.white : Colors.black87;

    String iconForAction(String action) {
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
                style: TextStyle(color: textColor()),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.street,
              style: TextStyle(
                color: textColor(),
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
                style: TextStyle(color: textColor().withValues(alpha: 0.6)),
              ),
            )
          else
            for (int i = 0; i < list.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () => _editAction(i, list[i]),
                  child: Card(
                    color: cardColor(),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(iconForAction(list[i].action)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${list[i].playerName}: ${list[i].action}${list[i].amount != null ? ' ${list[i].amount}' : ''}',
                              style: TextStyle(color: textColor()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          Row(
            children: [
              TextButton(
                onPressed: () => context
                    .read<ActionSyncService>()
                    .undoLastAction(widget.street),
                child: const Text('Undo Last Action'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => context
                    .read<ActionSyncService>()
                    .clearStreet(widget.street),
                child: const Text('Clear Street'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
