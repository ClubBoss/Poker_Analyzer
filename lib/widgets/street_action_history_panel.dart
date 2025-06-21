import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'collapsible_street_section.dart';

/// Panel showing action history with collapsible sections for each street.
class StreetActionHistoryPanel extends StatelessWidget {
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

  const StreetActionHistoryPanel({
    super.key,
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
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => CollapsibleStreetSection(
          street: i,
          actions: actions,
          pots: pots,
          stackSizes: stackSizes,
          playerPositions: playerPositions,
          onEdit: onEdit,
          onDelete: onDelete,
          onInsert: onInsert,
          onDuplicate: onDuplicate,
          onReorder: onReorder,
          visibleCount: visibleCount,
          evaluateActionQuality: evaluateActionQuality,
        ),
      ),
    );
  }
}
