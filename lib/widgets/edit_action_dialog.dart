import 'package:flutter/material.dart';
import '../models/action_entry.dart';

Future<ActionEntry?> showEditActionDialog(
  BuildContext context, {
  required ActionEntry entry,
  required int numberOfPlayers,
  required Map<int, String> playerPositions,
}) {
  int player = entry.playerIndex;
  String action = entry.action;
  final controller = TextEditingController(
    text: entry.amount != null ? entry.amount.toString() : '',
  );

  return showDialog<ActionEntry>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final needAmount =
            action == 'bet' || action == 'raise' || action == 'call';
        return AlertDialog(
          title: const Text('Редактировать действие'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: player,
                items: [
                  for (int i = 0; i < numberOfPlayers; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(playerPositions[i] ?? 'Player ${i + 1}'),
                    ),
                ],
                onChanged: (v) => setState(() => player = v ?? player),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: action,
                items: const [
                  DropdownMenuItem(value: 'fold', child: Text('fold')),
                  DropdownMenuItem(value: 'check', child: Text('check')),
                  DropdownMenuItem(value: 'call', child: Text('call')),
                  DropdownMenuItem(value: 'bet', child: Text('bet')),
                  DropdownMenuItem(value: 'raise', child: Text('raise')),
                ],
                onChanged: (v) => setState(() => action = v ?? action),
              ),
              if (needAmount)
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final amount =
                    (action == 'bet' || action == 'raise' || action == 'call')
                    ? double.tryParse(controller.text)
                    : null;
                Navigator.pop(
                  ctx,
                  ActionEntry(entry.street, player, action, amount: amount),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    ),
  );
}
