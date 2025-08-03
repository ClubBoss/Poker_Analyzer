import 'package:flutter/material.dart';
import '../models/action_entry.dart';

import 'street_action_tile.dart';
import 'street_pot_widget.dart';

/// Список действий на конкретной улице
class StreetActionsList extends StatelessWidget {
  final int street;
  final List<ActionEntry> actions;
  final List<int> pots;
  final Map<int, int> stackSizes;
  final Map<int, String> playerPositions;
  final int numberOfPlayers;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final void Function(int)? onDuplicate;
  final int? visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;
  final void Function(ActionEntry, String?)? onManualEvaluationChanged;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(int index, ActionEntry entry)? onInsert;
  final double? sprValue;

  const StreetActionsList({
    super.key,
    required this.street,
    required this.actions,
    required this.pots,
    required this.stackSizes,
    required this.playerPositions,
    required this.numberOfPlayers,
    required this.onEdit,
    required this.onDelete,
    this.onInsert,
    this.onDuplicate,
    this.visibleCount,
    this.evaluateActionQuality,
    this.onManualEvaluationChanged,
    this.onReorder,
    this.sprValue,
  });

  @override
  Widget build(BuildContext context) {
    final relevantActions = visibleCount != null
        ? actions.take(visibleCount!).toList(growable: false)
        : actions;
    final streetActions =
        relevantActions.where((a) => a.street == street).toList(growable: false);
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
            child: ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                if (onReorder == null) return;
                final oldGlobal =
                    actions.indexOf(streetActions[oldIndex]);
                int newGlobal;
                if (newIndex >= streetActions.length) {
                  newGlobal = actions.indexOf(streetActions.last) + 1;
                } else {
                  final target =
                      streetActions[newIndex > oldIndex ? newIndex - 1 : newIndex];
                  newGlobal = actions.indexOf(target);
                  if (newIndex > oldIndex) newGlobal += 1;
                }
                onReorder!(oldGlobal, newGlobal);
              },
              itemCount: streetActions.length,
              itemBuilder: (context, index) {
                final entry = streetActions[index];
                final showDivider = index > 0 &&
                    (entry.action == 'bet' || entry.action == 'raise');
                return Dismissible(
                  key: ValueKey(entry.timestamp.microsecondsSinceEpoch),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    final index = actions.indexOf(entry);
                    onDelete(index);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Действие удалено'),
                        action: SnackBarAction(
                          label: 'Отмена',
                          onPressed: () {
                            if (onInsert != null) {
                              onInsert!(index, entry);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      if (showDivider)
                        const Divider(height: 4, color: Colors.white24),
                      StreetActionTile(
                        entry: entry,
                        previousEntry: actions.indexOf(entry) > 0
                            ? actions[actions.indexOf(entry) - 1]
                            : null,
                        index: index,
                        globalIndex: actions.indexOf(entry),
                        numberOfPlayers: numberOfPlayers,
                        playerPositions: playerPositions,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onDuplicate: onDuplicate,
                        visibleCount: visibleCount,
                        evaluateActionQuality: evaluateActionQuality,
                        onManualEvaluationChanged: onManualEvaluationChanged,
                        showDragHandle: onReorder != null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        StreetPotWidget(
          streetIndex: street,
          potSize: pots[street],
          sprValue: sprValue,
        ),
      ],
    );
  }
}
