import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'street_actions_list.dart';

class CollapsibleStreetSummary extends StatefulWidget {
  final List<ActionEntry> actions;
  final Map<int, String> playerPositions;
  final void Function(int) onEdit;
  final void Function(int) onDelete;

  const CollapsibleStreetSummary({
    super.key,
    required this.actions,
    required this.playerPositions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CollapsibleStreetSummary> createState() => _CollapsibleStreetSummaryState();
}

class _CollapsibleStreetSummaryState extends State<CollapsibleStreetSummary> {
  int? _expandedStreet;

  String _summaryForStreet(int street) {
    final streetActions = widget.actions.where((a) => a.street == street).toList();
    if (streetActions.isEmpty) return 'Нет действий';
    final parts = streetActions.map((a) {
      final pos = widget.playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}';
      final act = '${a.action}${a.amount != null ? ' ${a.amount}' : ''}';
      return '$act $pos';
    }).toList();
    return parts.join(' → ');
  }

  @override
  Widget build(BuildContext context) {
    const streetNames = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'];
    return Column(
      children: List.generate(4, (i) {
        final expanded = _expandedStreet == i;
        final summary = _summaryForStreet(i);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedStreet = expanded ? null : i;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${streetNames[i]}: $summary',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                ClipRect(
                  child: AnimatedAlign(
                    alignment: Alignment.topCenter,
                    duration: const Duration(milliseconds: 300),
                    heightFactor: expanded ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: StreetActionsList(
                        street: i,
                        actions: widget.actions,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
