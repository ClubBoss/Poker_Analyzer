import 'package:flutter/material.dart';
import '../models/action_entry.dart';

class ActionHistoryWidget extends StatelessWidget {
  final List<ActionEntry> actions;
  final Map<int, String> playerPositions;
  final Function(int street)? onExpand;

  const ActionHistoryWidget({
    Key? key,
    required this.actions,
    required this.playerPositions,
    this.onExpand,
  }) : super(key: key);

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  @override
  Widget build(BuildContext context) {
    const streetNames = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int street = 0; street < 4; street++)
          _buildStreetTile(context, street, streetNames[street]),
      ],
    );
  }

  Widget _buildStreetTile(BuildContext context, int street, String title) {
    final streetActions = actions
        .where((a) => a.street == street && !a.generated)
        .toList();
    if (streetActions.isEmpty) return const SizedBox.shrink();

    final last = streetActions.last;
    final pos = playerPositions[last.playerIndex] ?? 'P${last.playerIndex + 1}';
    final lastAction =
        '${_capitalize(last.action)}${last.amount != null ? ' ${last.amount}' : ''}';
    final header = '$title - $lastAction от $pos';

    return ExpansionTile(
      title: Text(header, style: const TextStyle(color: Colors.white)),
      collapsedTextColor: Colors.white,
      textColor: Colors.white,
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onExpansionChanged: (expanded) {
        if (expanded && onExpand != null) onExpand!(street);
      },
      children: [
        for (int i = 0; i < streetActions.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Colors.white24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _actionLine(streetActions[i]),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  String _actionLine(ActionEntry a) {
    final pos = playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}';
    final label = a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action;
    final act = '$label${a.amount != null ? ' ${a.amount}' : ''}';
    return '$pos - $act';
  }
}
