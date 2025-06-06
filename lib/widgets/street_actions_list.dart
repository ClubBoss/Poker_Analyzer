import 'package:flutter/material.dart';
import '../models/action_entry.dart';

/// Список действий на конкретной улице
class StreetActionsList extends StatelessWidget {
  final int street;
  final List<ActionEntry> actions;
  final void Function(int) onEdit;
  final void Function(int) onDelete;

  const StreetActionsList({
    super.key,
    required this.street,
    required this.actions,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildTile(ActionEntry a, int globalIndex) {
    final amountStr = a.amount != null ? ' ${a.amount}' : '';
    Color color;
    switch (a.action) {
      case 'fold':
        color = Colors.red;
        break;
      case 'call':
        color = Colors.blue;
        break;
      case 'raise':
        color = Colors.green;
        break;
      case 'check':
        color = Colors.grey;
        break;
      default:
        color = Colors.white;
    }
    final title = a.generated
        ? 'Игрок ${a.playerIndex + 1}: ${a.action}$amountStr (auto)'
        : 'Игрок ${a.playerIndex + 1}: ${a.action}$amountStr';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontStyle: a.generated ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      onTap: () => onEdit(globalIndex),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => onDelete(globalIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streetActions =
        actions.where((a) => a.street == street).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Действия',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        if (streetActions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Действий нет',
                style: TextStyle(color: Colors.white54)),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (int index = 0; index < streetActions.length; index++) ...[
                  if (index > 0 &&
                      (streetActions[index].action == 'bet' ||
                          streetActions[index].action == 'raise'))
                    const Divider(height: 4, color: Colors.white24),
                  _buildTile(streetActions[index], actions.indexOf(streetActions[index])),
                ]
              ],
            ),
          ),
      ],
    );
  }
}
