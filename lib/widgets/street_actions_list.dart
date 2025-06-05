import 'package:flutter/material.dart';
import '../models/action_entry.dart';

/// Список действий на конкретной улице
class StreetActionsList extends StatelessWidget {
  final int street;
  final List<ActionEntry> actions;

  const StreetActionsList({
    super.key,
    required this.street,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final streetActions =
        actions.where((a) => a.street == street).toList(growable: false);
    final pot = streetActions
        .where((a) => ['call', 'bet', 'raise'].contains(a.action))
        .fold<int>(0, (sum, a) => sum + (a.amount ?? 0));

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
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: streetActions.length,
              itemBuilder: (context, index) {
                final a = streetActions[index];
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
                return Text(
                  'Игрок ${a.playerIndex + 1}: ${a.action}$amountStr',
                  style: TextStyle(color: color),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Пот: $pot',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
