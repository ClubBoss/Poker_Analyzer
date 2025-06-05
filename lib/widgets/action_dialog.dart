import 'package:flutter/material.dart';
import '../models/action_entry.dart';

/// Диалог ввода действия игрока
Future<ActionEntry?> showActionDialog(
  BuildContext context, {
  required int street,
  required int playerCount,
  int? initialPlayer,
}) {
  return showDialog<ActionEntry>(
    context: context,
    builder: (ctx) {
      int selectedPlayer = initialPlayer ?? 0;
      String selectedAction = 'check';
      final actions = ['fold', 'check', 'call', 'bet', 'raise'];
      final TextEditingController amountController = TextEditingController();
      return StatefulBuilder(
        builder: (context, setState) {
          final needAmount =
              selectedAction == 'bet' ||
              selectedAction == 'raise' ||
              selectedAction == 'call';
          return AlertDialog(
            title: const Text('Добавить действие'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: selectedPlayer,
                  items: List.generate(
                    playerCount,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text('Игрок ${i + 1}'),
                    ),
                  ),
                  onChanged: (v) => setState(() => selectedPlayer = v ?? 0),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedAction,
                  items: actions
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedAction = v ?? actions.first),
                ),
                if (needAmount) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Количество фишек'),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  final amount = int.tryParse(amountController.text);
                  Navigator.pop(
                    ctx,
                    ActionEntry(
                      street: street,
                      playerIndex: selectedPlayer,
                      action: selectedAction,
                      amount: needAmount ? amount : null,
                    ),
                  );
                },
                child: const Text('Добавить'),
              ),
            ],
          );
        },
      );
    },
  );
}
