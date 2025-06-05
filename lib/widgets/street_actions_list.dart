import 'package:flutter/material.dart';
import '../models/action_entry.dart';

/// Список действий на конкретной улице
class StreetActionsList extends StatelessWidget {
  final int street;
  final List<ActionEntry> actions;
  final VoidCallback onAdd;

  const StreetActionsList({
    super.key,
    required this.street,
    required this.actions,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final streetActions =
        actions.where((a) => a.street == street).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Действия',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: onAdd,
              child: const Text('Добавить действие'),
            ),
          ],
        ),
        if (streetActions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Действий нет',
                style: TextStyle(color: Colors.white54)),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: streetActions.length,
              itemBuilder: (context, index) {
                final a = streetActions[index];
                final amountStr =
                    a.amount != null ? ' ${a.amount}' : '';
                return Text(
                  'Игрок ${a.playerIndex + 1}: ${a.action}$amountStr',
                  style: const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
      ],
    );
  }
}
