import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'bet_sizer.dart';

/// Dialog allowing to quickly choose an action for a player.
class ActionDialog extends StatefulWidget {
  final int playerIndex;
  final int street;
  final int stackSize;
  final int pot;

  const ActionDialog({
    super.key,
    required this.playerIndex,
    required this.street,
    required this.stackSize,
    required this.pot,
  });

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

enum _Action { fold, check, call, bet, raise }

class _ActionDialogState extends State<ActionDialog> {
  _Action? _selected;

  @override
  void initState() {
    super.initState();
  }

  void _selectSimple(_Action act) {
    Navigator.pop(
      context,
      ActionEntry(widget.street, widget.playerIndex, act.name, amount: null),
    );
  }

  void _selectBetAmount(double amount) {
    Navigator.pop(
      context,
      ActionEntry(widget.street, widget.playerIndex, _selected!.name,
          amount: amount.clamp(1, widget.stackSize.toDouble())),
    );
  }

  Widget _actionButton(String label, _Action act) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _selected == act ? Colors.blueGrey : Colors.black87,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () {
        if (act == _Action.fold || act == _Action.check || act == _Action.call) {
          _selectSimple(act);
        } else {
          setState(() {
            _selected = act;
          });
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text(
        'Choose action for Player ${widget.playerIndex + 1}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton('Fold', _Action.fold),
          const SizedBox(height: 8),
          _actionButton('Check', _Action.check),
          const SizedBox(height: 8),
          _actionButton('Call', _Action.call),
          const SizedBox(height: 8),
          _actionButton('Bet', _Action.bet),
          const SizedBox(height: 8),
          _actionButton('Raise', _Action.raise),
          if (_selected == _Action.bet || _selected == _Action.raise)
            BetSizer(
              stackSize: widget.stackSize,
              pot: widget.pot,
              onSelected: _selectBetAmount,
            ),
        ],
      ),
    );
  }
}
