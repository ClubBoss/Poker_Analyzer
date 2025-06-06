import 'package:flutter/material.dart';
import '../models/action_entry.dart';

class ActionDialog extends StatefulWidget {
  final int playerIndex;
  final int street;
  final int pot;
  final int stackSize;
  final String? initialAction;
  final int? initialAmount;

  const ActionDialog({
    Key? key,
    required this.playerIndex,
    required this.street,
    required this.pot,
    required this.stackSize,
    this.initialAction,
    this.initialAmount,
  }) : super(key: key);

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  late double _currentAmount;

  @override
  void initState() {
    super.initState();
    _currentAmount = (widget.initialAmount ?? 0).toDouble();
  }

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
    final action = widget.initialAction ?? 'bet';

    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text(
        'Размер ставки игрока ${widget.playerIndex + 1}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSizingButton('1/3 Пот', (widget.pot / 3).round()),
              _buildSizingButton('1/2 Пот', (widget.pot / 2).round()),
              _buildSizingButton('Пот', widget.pot),
              _buildSizingButton('Олл-ин', widget.stackSize),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = _currentAmount.round();
            Navigator.pop(
              context,
              ActionEntry(
                widget.street,
                widget.playerIndex,
                action,
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
