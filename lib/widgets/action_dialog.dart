import 'package:flutter/material.dart';
import '../models/action_entry.dart';

class ActionDialog extends StatefulWidget {
  final int playerIndex;
  final int street;
  final String position;
  final int stackSize;
  final int pot;
  final String? initialAction;
  final int? initialAmount;

  const ActionDialog({
    super.key,
    required this.playerIndex,
    required this.street,
    required this.position,
    required this.stackSize,
    required this.pot,
    this.initialAction,
    this.initialAmount,
  });

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  late String _action;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _action = widget.initialAction ?? 'fold';
    _controller = TextEditingController(
        text: widget.initialAmount != null ? widget.initialAmount.toString() : '');
  }

  bool get _needsAmount =>
      _action == 'bet' || _action == 'raise' || _action == 'call';

  int? get _amount {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(digits);
  }

  void _confirm() {
    Navigator.pop(
      context,
      ActionEntry(widget.street, widget.playerIndex, _action,
          amount: _needsAmount ? _amount : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(color: Colors.white);
    final actions = ['fold', 'check', 'call', 'bet', 'raise'];
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text(
        'Игрок ${widget.playerIndex + 1} (${widget.position})',
        style: textStyle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _action,
            dropdownColor: Colors.black87,
            decoration: const InputDecoration(
              labelText: 'Действие',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            items: [
              for (final a in actions)
                DropdownMenuItem(
                  value: a,
                  child: Text(a, style: textStyle),
                )
            ],
            onChanged: (value) => setState(() => _action = value!),
          ),
          if (_needsAmount)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                style: textStyle,
                decoration: const InputDecoration(
                  labelText: 'Размер',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: !_needsAmount || _amount != null ? _confirm : null,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
