import 'package:flutter/material.dart';
import '../models/action_entry.dart';

/// Диалог ввода действия игрока
Future<ActionEntry?> showActionDialog(
  BuildContext context, {
  required int street,
  required int playerIndex,
  required int callAmount,
  required bool hasBet,
}) {
  return showDialog<ActionEntry>(
    context: context,
    builder: (ctx) {
      String selectedAction = callAmount > 0 ? 'call' : 'check';
      final TextEditingController amountController = TextEditingController();
      return StatefulBuilder(
        builder: (context, setState) {
          final needAmount =
              selectedAction == 'bet' || selectedAction == 'raise';

          Widget actionButton(String action, String label, Color color) {
            final isSelected = selectedAction == action;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: () => setState(() => selectedAction = action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith(
                      (states) => isSelected ? color.withOpacity(0.8) : color,
                    ),
                  ),
                  child: Text(label, textAlign: TextAlign.center),
                ),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: Colors.grey[200],
            title: const Text('Добавить действие'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      actionButton('fold', 'Fold', Colors.red),
                      actionButton(
                          callAmount > 0 ? 'call' : 'check',
                          callAmount > 0 ? 'Call ($callAmount)' : 'Check',
                          Colors.blue),
                      actionButton(
                          hasBet ? 'raise' : 'bet',
                          hasBet ? 'Raise' : 'Bet',
                          Colors.green),
                    ],
                  ),
                  if (needAmount) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Количество фишек',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  int? amount;
                  if (selectedAction == 'call') {
                    amount = callAmount;
                  } else if (needAmount) {
                    amount = int.tryParse(amountController.text);
                  }
                  Navigator.pop(
                    ctx,
                    ActionEntry(
                      street,
                      playerIndex,
                      selectedAction,
                      amount,
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
