import 'package:flutter/material.dart';
import '../models/action_entry.dart';

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

class _ActionDescriptor {
  final String label;
  final _Action action;
  const _ActionDescriptor(this.label, this.action);
}

class _ActionDialogState extends State<ActionDialog> {
  static const List<_ActionDescriptor> _actions = [
    _ActionDescriptor('Fold', _Action.fold),
    _ActionDescriptor('Check', _Action.check),
    _ActionDescriptor('Call', _Action.call),
    _ActionDescriptor('Bet', _Action.bet),
    _ActionDescriptor('Raise', _Action.raise),
  ];
  _Action? _selected;
  double _slider = 0;

  @override
  void initState() {
    super.initState();
    _slider = 0;
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

  void _onSliderChange(double value) {
    setState(() => _slider = value);
    final amt = value;
    if (amt > 0) {
      _selectBetAmount(amt);
    }
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
            _slider = 0;
          });
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 20)),
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
          for (int i = 0; i < _actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _actionButton(_actions[i].label, _actions[i].action),
          ],
          if (_selected == _Action.bet || _selected == _Action.raise)
            _buildBetSizer(),
        ],
      ),
    );
  }
}
