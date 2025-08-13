import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'edit_action_dialog.dart';

class ActionEditorList extends StatefulWidget {
  final List<ActionEntry> initial;
  final int players;
  final List<String> positions;
  final ValueChanged<List<ActionEntry>> onChanged;
  const ActionEditorList({
    super.key,
    required this.initial,
    required this.players,
    required this.positions,
    required this.onChanged,
  });

  @override
  State<ActionEditorList> createState() => _ActionEditorListState();
}

class _ActionEditorListState extends State<ActionEditorList> {
  late List<ActionEntry> _actions;

  @override
  void initState() {
    super.initState();
    _actions = List.from(widget.initial);
  }

  Future<void> _addAction() async {
    final entry = await showEditActionDialog(
      context,
      entry: ActionEntry(0, 0, 'call'),
      numberOfPlayers: widget.players,
      playerPositions: {
        for (int i = 0; i < widget.positions.length; i++) i: widget.positions[i]
      },
    );
    if (entry != null) {
      setState(() {
        _actions.add(entry);
      });
      widget.onChanged(List.from(_actions));
    }
  }

  Future<void> _edit(int index) async {
    final edited = await showEditActionDialog(
      context,
      entry: _actions[index],
      numberOfPlayers: widget.players,
      playerPositions: {
        for (int i = 0; i < widget.positions.length; i++) i: widget.positions[i]
      },
    );
    if (edited != null) {
      setState(() {
        _actions[index] = edited;
      });
      widget.onChanged(List.from(_actions));
    }
  }

  void _delete(int index) {
    setState(() => _actions.removeAt(index));
    widget.onChanged(List.from(_actions));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < _actions.length; i++)
          ListTile(
            title: Text(
              '${widget.positions[_actions[i].playerIndex]}: ${_actions[i].action}${_actions[i].amount != null ? ' ${_actions[i].amount}' : ''}',
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () => _edit(i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _delete(i),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: _addAction,
          icon: const Icon(Icons.add),
          label: const Text('Add action'),
        ),
      ],
    );
  }
}
