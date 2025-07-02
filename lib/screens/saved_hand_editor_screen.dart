import 'package:flutter/material.dart';
import '../models/saved_hand.dart';
import '../models/action_entry.dart';
import '../theme/app_colors.dart';

class SavedHandEditorScreen extends StatefulWidget {
  final SavedHand hand;
  const SavedHandEditorScreen({super.key, required this.hand});

  @override
  State<SavedHandEditorScreen> createState() => _SavedHandEditorScreenState();
}

class _SavedHandEditorScreenState extends State<SavedHandEditorScreen> {
  late Map<int, List<ActionEntry>> _actions;

  @override
  void initState() {
    super.initState();
    _actions = {for (var s = 0; s < 4; s++) s: <ActionEntry>[]};
    for (final a in widget.hand.actions) {
      _actions[a.street]!.add(
        ActionEntry(a.street, a.playerIndex, a.action, amount: a.amount),
      );
    }
  }

  void _add(int s) {
    setState(() => _actions[s]!.add(ActionEntry(s, 0, 'call')));
  }

  void _update(int s, int i, ActionEntry e) {
    setState(() => _actions[s]![i] = e);
  }

  void _remove(int s, int i) {
    setState(() => _actions[s]!.removeAt(i));
  }

  void _save() {
    final list = <ActionEntry>[];
    for (int s = 0; s < 4; s++) list.addAll(_actions[s]!);
    Navigator.pop(context, widget.hand.copyWith(actions: list));
  }

  @override
  Widget build(BuildContext context) {
    const names = ['Preflop', 'Flop', 'Turn', 'River'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Hand'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.check))],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (int s = 0; s < 4; s++)
              _StreetBlock(
                title: names[s],
                actions: _actions[s]!,
                playerCount: widget.hand.numberOfPlayers,
                onAdd: () => _add(s),
                onChanged: (i, e) => _update(s, i, e),
                onRemove: (i) => _remove(s, i),
              ),
          ],
        ),
      ),
    );
  }
}

class _StreetBlock extends StatelessWidget {
  final String title;
  final List<ActionEntry> actions;
  final int playerCount;
  final VoidCallback onAdd;
  final void Function(int index, ActionEntry entry) onChanged;
  final void Function(int index) onRemove;
  const _StreetBlock({
    required this.title,
    required this.actions,
    required this.playerCount,
    required this.onAdd,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      collapsedTextColor: Colors.white,
      textColor: Colors.white,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          itemBuilder: (_, i) => _ActionRow(
            entry: actions[i],
            playerCount: playerCount,
            onChanged: (e) => onChanged(i, e),
            onDelete: () => onRemove(i),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Action'),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatefulWidget {
  final ActionEntry entry;
  final int playerCount;
  final ValueChanged<ActionEntry> onChanged;
  final VoidCallback onDelete;
  const _ActionRow({
    required this.entry,
    required this.playerCount,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  late int player;
  late String action;
  late TextEditingController amount;

  @override
  void initState() {
    super.initState();
    player = widget.entry.playerIndex;
    action = widget.entry.action;
    amount = TextEditingController(
      text: widget.entry.amount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      ActionEntry(
        widget.entry.street,
        player,
        action,
        amount: double.tryParse(amount.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<int>(
          value: player,
          items: [
            for (int i = 0; i < widget.playerCount; i++)
              DropdownMenuItem(value: i, child: Text('P${i + 1}')),
          ],
          onChanged: (v) {
            setState(() => player = v ?? player);
            _emit();
          },
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: action,
          items: const [
            DropdownMenuItem(value: 'fold', child: Text('fold')),
            DropdownMenuItem(value: 'call', child: Text('call')),
            DropdownMenuItem(value: 'raise', child: Text('raise')),
            DropdownMenuItem(value: 'push', child: Text('push')),
            DropdownMenuItem(value: 'post', child: Text('post')),
          ],
          onChanged: (v) {
            setState(() => action = v ?? action);
            _emit();
          },
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextField(
            controller: amount,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(isDense: true, labelText: 'Amount'),
            onChanged: (_) => _emit(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: widget.onDelete,
        ),
      ],
    );
  }
}
