import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'street_actions_list.dart';

class CollapsibleStreetSummary extends StatefulWidget {
  final List<ActionEntry> actions;
  final Map<int, String> playerPositions;
  final List<int> pots;
  final Map<int, int> stackSizes;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final void Function(int) onDuplicate;
  final void Function(int, int)? onReorder;
  final int? visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;
  final void Function(int index, ActionEntry entry)? onInsert;

  const CollapsibleStreetSummary({
    super.key,
    required this.actions,
    required this.playerPositions,
    required this.pots,
    required this.stackSizes,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    this.onReorder,
    this.onInsert,
    this.visibleCount,
    this.evaluateActionQuality,
  });

  @override
  State<CollapsibleStreetSummary> createState() =>
      _CollapsibleStreetSummaryState();
}

class _CollapsibleStreetSummaryState extends State<CollapsibleStreetSummary> {
  int? _expandedStreet;

  Color _colorForAction(String action) {
    switch (action) {
      case 'fold':
        return Colors.red;
      case 'call':
        return Colors.blue;
      case 'raise':
      case 'bet':
        return Colors.green;
      case 'custom':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  Widget _buildHeaderSummary(List<ActionEntry> actions) {
    if (actions.isEmpty) {
      return const Text(
        'Нет действий',
        style: TextStyle(color: Colors.white54),
      );
    }
    final last = actions.last;
    final pos =
        widget.playerPositions[last.playerIndex] ?? 'P${last.playerIndex + 1}';
    final label =
        last.action == 'custom' ? (last.customLabel ?? 'custom') : last.action;
    final actionText =
        '${_capitalize(label)}${last.amount != null ? ' ${last.amount}' : ''}';
    return Text(
      '$pos $actionText',
      style: TextStyle(color: _colorForAction(last.action)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const streetNames = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'];
    return Column(
      children: List.generate(4, (i) {
        final expanded = _expandedStreet == i;
        final streetActions =
            widget.actions.where((a) => a.street == i).toList(growable: false);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          streetNames[i],
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        _buildHeaderSummary(streetActions),
                      ],
                    ),
                  ),
                ),
                ClipRect(
                  child: AnimatedAlign(
                    alignment: Alignment.topCenter,
                    duration: const Duration(milliseconds: 300),
                    heightFactor: expanded ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: StreetActionsList(
                        street: i,
                        actions: widget.actions,
                        pots: widget.pots,
                        stackSizes: widget.stackSizes,
                        playerPositions: widget.playerPositions,
                        numberOfPlayers: widget.playerPositions.length,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                        onInsert: widget.onInsert,
                        onDuplicate: widget.onDuplicate,
                        onReorder: widget.onReorder,
                        visibleCount: widget.visibleCount,
                        evaluateActionQuality: widget.evaluateActionQuality,
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
