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
    barrierDismissible: true,
    builder: (ctx) {
      final TextEditingController amountController = TextEditingController();

      Widget actionButton(String action, String label, Color color) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton(
              onPressed: () {
                int? amount;
                if (action == 'call') {
                  amount = callAmount;
                } else if (action == 'bet' || action == 'raise') {
                  amount = int.tryParse(amountController.text);
                  if (amount == null) return;
                }
                Navigator.pop(
                  ctx,
                  ActionEntry(street, playerIndex, action, amount),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
        );
      }

      return AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Выберите действие',
          style: TextStyle(color: Colors.white),
        ),
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
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Количество фишек',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    },
  );
}
