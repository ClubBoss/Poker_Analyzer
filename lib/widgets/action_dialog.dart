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
        ActionEntry(widget.street, widget.playerIndex, action,
            amount: null),
      );
    } else {
      setState(() => _selectedAction = action);
    }
  }

  Widget _actionButton(String label, String action, IconData icon) {
    final bool active = _selectedAction == action;
    final double scale = active ? 1.05 : 1.0;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: active || _selectedAction == null ? 1.0 : 0.6,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(scale),
        child: SizedBox(
          width: 110,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: active ? Colors.blueGrey : Colors.grey[850],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onPressed: () => _onActionPressed(action),
            icon: Icon(icon),
            label: Text(label, style: const TextStyle(fontSize: 19)),
          ),
        ),
      ),
    );
  }

  void _onBetSelected(int amount) {
    Navigator.pop(
      context,
      ActionEntry(widget.street, widget.playerIndex, _selectedAction!,
          amount: amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
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
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionButton('Fold', 'fold', Icons.close),
              _actionButton('Check', 'check', Icons.remove),
              _actionButton('Call', 'call', Icons.call),
              _actionButton('Bet', 'bet', Icons.south),
              _actionButton('Raise', 'raise', Icons.north),
            ],
          ),
          if (_selectedAction == 'bet' || _selectedAction == 'raise')
            Padding(
              padding: const EdgeInsets.all(16),
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
