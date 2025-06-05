import 'package:flutter/material.dart';
import '../models/action_entry.dart';

class ActionDialog extends StatefulWidget {
  final int playerIndex;
  final int street;
  const ActionDialog({Key? key, required this.playerIndex, required this.street}) : super(key: key);

  @override
  _ActionDialogState createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  String selectedAction = 'Check';
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Выберите действие для игрока ${widget.playerIndex + 1}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: selectedAction,
            items: ['Fold', 'Check', 'Call', 'Bet', 'Raise']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedAction = value);
              }
            },
          ),
          if (selectedAction == 'Bet' || selectedAction == 'Raise')
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Сумма'),
              keyboardType: TextInputType.number,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = int.tryParse(_amountController.text);
            Navigator.pop(
              context,
              ActionEntry(widget.street, widget.playerIndex, selectedAction.toLowerCase(), amount),
            );
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
