import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import '../helpers/action_color_helper.dart';
import 'street_actions_list.dart';

/// Collapsible block showing actions for a specific street.
class CollapsibleStreetSection extends StatefulWidget {
  final int street;
  final List<ActionEntry> actions;
  final List<int> pots;
  final Map<int, int> stackSizes;
  final Map<int, String> playerPositions;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final void Function(int) onDuplicate;
  final void Function(int, int)? onReorder;
  final int? visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;
  final void Function(int index, ActionEntry entry)? onInsert;

  const CollapsibleStreetSection({
    super.key,
    required this.street,
    required this.actions,
    required this.pots,
    required this.stackSizes,
    required this.playerPositions,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    this.onReorder,
    this.onInsert,
    this.visibleCount,
    this.evaluateActionQuality,
  });

  @override
  State<CollapsibleStreetSection> createState() =>
      _CollapsibleStreetSectionState();
}

class _CollapsibleStreetSectionState extends State<CollapsibleStreetSection> {
  bool _open = false;

  String get _streetName => ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][widget.street];

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  String _buildSummary(List<ActionEntry> actions) {
    if (actions.isEmpty) return 'Нет действий';
    return actions
        .map((a) {
          final label = a.action == 'custom'
              ? (a.customLabel ?? 'custom')
              : a.action;
          return '${_capitalize(label)}${a.amount != null ? ' ${a.amount}' : ''}';
        })
        .join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    final relevant = widget.visibleCount != null
        ? widget.actions.take(widget.visibleCount!).toList(growable: false)
        : widget.actions;
    final streetActions = relevant
        .where((a) => a.street == widget.street)
        .toList(growable: false);

    final summary = _buildSummary(streetActions);
    final summaryColor = streetActions.isNotEmpty
        ? actionColor(streetActions.last.action)
        : Colors.white54;
    bool hasNegative = false;
    if (widget.evaluateActionQuality != null) {
      for (final a in streetActions) {
        final q = widget.evaluateActionQuality!(a).toLowerCase();
        if (q.contains('bad') || q.contains('плох') || q.contains('ошиб')) {
          hasNegative = true;
          break;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _open ? Colors.black54 : Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _streetName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasNegative) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.warning,
                                color: Colors.red,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(summary, style: TextStyle(color: summaryColor)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 300),
              heightFactor: _open ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: StreetActionsList(
                  street: widget.street,
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
    );
  }
}
