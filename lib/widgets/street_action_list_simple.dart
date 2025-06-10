import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/action_sync_service.dart';
import '../models/player_zone_action_entry.dart';

class StreetActionListSimple extends StatelessWidget {
  final String street;

  const StreetActionListSimple({super.key, required this.street});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ActionEntry>> actions =
        context.watch<ActionSyncService>().actions;
    final list = actions[street] ?? [];
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          street,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        for (final a in list)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${a.playerName}: ${a.action}${a.amount != null ? ' ${a.amount}' : ''}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
