import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'bet_sizer.dart';

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
  String? _selectedAction;

  @override
  void initState() {
    super.initState();
    _selectedAction = widget.initialAction;
  }

  void _onActionPressed(String action) {
    if (action == 'fold' || action == 'check' || action == 'call') {
      Navigator.pop(
        context,
        ActionEntry(widget.street, widget.playerIndex, action, null),
      );
    } else {
      setState(() => _selectedAction = action);
    }
  }

  Widget _actionButton(String label, String action) {
    final bool active = _selectedAction == action;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? Colors.blueGrey : Colors.white12,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
      onPressed: () => _onActionPressed(action),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  void _onBetSelected(int amount) {
    Navigator.pop(
      context,
      ActionEntry(widget.street, widget.playerIndex, _selectedAction!, amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      titlePadding: const EdgeInsets.only(left: 24, right: 8, top: 20, bottom: 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Выберите действие игрока ${widget.playerIndex + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton('Fold', 'fold'),
              _actionButton('Check', 'check'),
              _actionButton('Call', 'call'),
              _actionButton('Bet', 'bet'),
              _actionButton('Raise', 'raise'),
            ],
          ),
          if (_selectedAction == 'bet' || _selectedAction == 'raise')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: BetSizer(
                pot: widget.pot,
                stackSize: widget.stackSize,
                onSelected: _onBetSelected,
              ),
            ),
        ],
      ),
    );
  }
}
