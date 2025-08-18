import 'package:flutter/material.dart';
import '../models/action_entry.dart';

/// Horizontal bar showing brief actions for the current street.
class StreetActionSummaryBar extends StatelessWidget {
  final int street;
  final List<ActionEntry> actions;
  final Map<int, String> playerPositions;
  final VoidCallback onActionTap;

  const StreetActionSummaryBar({
    super.key,
    required this.street,
    required this.actions,
    required this.playerPositions,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final streetActions = actions
        .where((a) => a.street == street)
        .toList(growable: false);
    if (streetActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      color: Colors.black.withValues(alpha: 0.3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final a in streetActions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: onActionTap,
                  child: Chip(
                    backgroundColor: Colors.black54,
                    label: Text(
                      '${playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}'}: '
                      '${a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action}${a.amount != null ? ' ${a.amount}' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
