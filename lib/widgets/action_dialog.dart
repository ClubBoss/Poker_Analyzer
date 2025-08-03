import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import '../models/poker_actions.dart';

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
  String? _selected;
  double _slider = 0;

  @override
  void initState() {
    super.initState();
    _slider = 0;
  }

  void _selectSimple(String act) {
    Navigator.pop(
      context,
      ActionEntry(widget.street, widget.playerIndex, act, amount: null),
    );
  }

  void _selectBetAmount(double amount) {
    Navigator.pop(
      context,
      ActionEntry(widget.street, widget.playerIndex, _selected!,
          amount: amount.clamp(1, widget.stackSize.toDouble())),
    );
  }

  void _onSliderChange(double value) {
    setState(() => _slider = value);
    final amt = value;
    if (amt > 0) {
      _selectBetAmount(amt);
    }
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
            _slider = 0;
          });
        }
      },
      icon: Text(action.icon, style: const TextStyle(fontSize: 20)),
      label: Text(action.label, style: const TextStyle(fontSize: 20)),
    );
  }

  Widget _buildBetSizer() {
    final int max = widget.stackSize;
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final f in [1 / 3, 0.5, 0.75, 1.0])
              OutlinedButton(
                onPressed: () {
                  final amount = widget.pot * f;
                  _selectBetAmount(amount);
                },
                child: Text('${(f * 100).round()}%'),
              ),
          ],
        ),
        Slider(
          value: _slider,
          min: 0,
          max: max.toDouble(),
          divisions: max,
          label: _slider.round().toString(),
          onChanged: _onSliderChange,
        ),
        Text('Amount: ${_slider.round()}',
            style: const TextStyle(color: Colors.white)),
      ],
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
