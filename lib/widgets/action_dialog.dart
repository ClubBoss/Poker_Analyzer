import 'package:flutter/material.dart';
import '../models/action_entry.dart';

class ActionDialog extends StatefulWidget {
  final int playerIndex;
  final int street;
  final int pot;
  final int stackSize;

  const ActionDialog({
    Key? key,
    required this.playerIndex,
    required this.street,
    required this.pot,
    required this.stackSize,
  }) : super(key: key);

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  String _selectedAction = 'check';
  double _currentAmount = 0;

  Widget _buildSizingButton(String label, int amount) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        setState(() {
          _currentAmount =
              amount.toDouble().clamp(0, widget.stackSize.toDouble());
        });
      },
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = ['fold', 'check', 'call', 'bet', 'raise'];

    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text(
        'Выберите действие для игрока ${widget.playerIndex + 1}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: _selectedAction,
            dropdownColor: Colors.black87,
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: Colors.white,
            items: actions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(color: Colors.white)),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedAction = val);
              }
            },
          ),
          if (_selectedAction == 'bet' ||
              _selectedAction == 'raise' ||
              _selectedAction == 'call') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSizingButton('1/2 Pot', (widget.pot / 2).round()),
                _buildSizingButton('Pot', widget.pot),
                _buildSizingButton('All-in', widget.stackSize),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: _currentAmount.clamp(0, widget.stackSize.toDouble()),
              min: 0,
              max: widget.stackSize.toDouble(),
              divisions: widget.stackSize > 0 ? widget.stackSize : 1,
              label: _currentAmount.round().toString(),
              onChanged: (val) => setState(() => _currentAmount = val),
            ),
            Text(
              _currentAmount.round().toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            int? amount;
            if (_selectedAction == 'bet' ||
                _selectedAction == 'raise' ||
                _selectedAction == 'call') {
              amount = _currentAmount.round();
            }
            Navigator.pop(
              context,
              ActionEntry(
                widget.street,
                widget.playerIndex,
                _selectedAction,
                amount,
              ),
            );
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
