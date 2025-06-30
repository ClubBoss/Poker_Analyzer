import 'package:flutter/material.dart';
import '../models/action_entry.dart';

class ActionListWidget extends StatefulWidget {
  final int playerCount;
  final ValueChanged<List<ActionEntry>> onChanged;
  final List<ActionEntry>? initial;
  const ActionListWidget({super.key, required this.playerCount, required this.onChanged, this.initial});

  @override
  State<ActionListWidget> createState() => _ActionListWidgetState();
}

class _ActionListWidgetState extends State<ActionListWidget> {
  late List<ActionEntry> _actions;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _actions = List<ActionEntry>.from(widget.initial ?? []);
    _controllers = [
      for (final a in _actions) TextEditingController(text: '${a.amount ?? 0}')
    ];
  }

  void _notify() => widget.onChanged(List<ActionEntry>.from(_actions));

  void _addAction() {
    setState(() {
      _actions.add(ActionEntry(0, 0, 'call', amount: 0));
      _controllers.add(TextEditingController(text: '0'));
    });
    _notify();
  }

  void _updatePlayer(int index, int value) {
    final a = _actions[index];
    setState(() => _actions[index] = ActionEntry(a.street, value, a.action, amount: a.amount));
    _notify();
  }

  void _updateAction(int index, String value) {
    final a = _actions[index];
    setState(() {
      _actions[index] = ActionEntry(a.street, a.playerIndex, value, amount: a.amount);
      if (value == 'fold') _controllers[index].text = '';
    });
    _notify();
  }

  void _updateAmount(int index, String value) {
    final a = _actions[index];
    final amt = int.tryParse(value);
    setState(() => _actions[index] = ActionEntry(a.street, a.playerIndex, a.action, amount: amt));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _actions.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _actions[i].action == 'post'
                ? Row(
                    children: [
                      Text('${_actions[i].playerIndex}'),
                      const SizedBox(width: 8),
                      const Text('post'),
                      const SizedBox(width: 8),
                      Text('${_actions[i].amount}'),
                    ],
                  )
                : Row(
                    children: [
                      DropdownButton<int>(
                        value: _actions[i].playerIndex,
                        items: [
                          for (int p = 0; p < widget.playerCount; p++)
                            DropdownMenuItem(value: p, child: Text('$p')),
                        ],
                        onChanged: (v) => _updatePlayer(i, v ?? 0),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _actions[i].action,
                        items: const [
                          DropdownMenuItem(value: 'fold', child: Text('fold')),
                          DropdownMenuItem(value: 'call', child: Text('call')),
                          DropdownMenuItem(value: 'raise', child: Text('raise')),
                          DropdownMenuItem(value: 'push', child: Text('push')),
                        ],
                        onChanged: (v) => _updateAction(i, v ?? 'call'),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _controllers[i],
                          keyboardType: TextInputType.number,
                          enabled: _actions[i].action != 'fold',
                          onChanged: (v) => _updateAmount(i, v),
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ),
                    ],
                  ),
          ),
        TextButton(
          onPressed: _addAction,
          child: const Text('＋ Add action'),
        ),
      ],
    );
  }
}
