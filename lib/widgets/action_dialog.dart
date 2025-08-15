import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import '../models/poker_actions.dart';
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

class _ActionDialogState extends State<ActionDialog> {
  static double? _lastAmountChips;
  String? _selected;
  double _amount = 1;

  void _selectSimple(String act) {
    Navigator.pop(
      context,
      ActionEntry(widget.street, widget.playerIndex, act, amount: null),
    );
  }

  void _selectBetAmount(double amount) {
    _lastAmountChips = amount.toDouble();
    Navigator.pop(
      context,
      ActionEntry(widget.street, widget.playerIndex, _selected!,
          amount: amount.clamp(1, widget.stackSize.toDouble())),
    );
  }

  Widget _actionButton(PokerAction action) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _selected == action.value ? Colors.blueGrey : Colors.black87,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () {
        if (action.value == 'fold' ||
            action.value == 'check' ||
            action.value == 'call') {
          _selectSimple(action.value);
        } else {
          setState(() {
            _selected = action.value;
            _amount = 1;
          });
        }
      },
      icon: Text(action.icon, style: const TextStyle(fontSize: 20)),
      label: Text(action.label, style: const TextStyle(fontSize: 20)),
    );
  }

  Widget _buildBetSizer() {
    return BetSizer(
      min: 1,
      max: widget.stackSize.toDouble(),
      value: _amount,
      bb: 1.0,
      pot: widget.pot.toDouble(),
      stack: widget.stackSize.toDouble(),
      recall: _lastAmountChips,
      adaptive: true,
      street: widget.street,
      spr: widget.pot > 0 ? (widget.stackSize / widget.pot) : null,
      onChanged: (v) => setState(() => _amount = v),
      onConfirm: () => _selectBetAmount(_amount),
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
          for (int i = 0; i < pokerActions.length; i++) ...[
            _actionButton(pokerActions[i]),
            if (i != pokerActions.length - 1) const SizedBox(height: 8),
          ],
          if (_selected == 'bet' || _selected == 'raise') _buildBetSizer(),
        ],
      ),
    );
  }
}
