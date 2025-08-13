import 'package:flutter/material.dart';

import '../models/action_entry.dart';
import '../helpers/action_formatting_helper.dart';
import '../services/action_history_service.dart';
import 'edit_action_dialog.dart';

class ActionHistoryOverlay extends StatelessWidget {
  final ActionHistoryService actionHistory;
  final Map<int, String> playerPositions;
  final Set<int> expandedStreets;
  final ValueChanged<int>? onToggleStreet;
  final void Function(int index, ActionEntry entry)? onEdit;
  final void Function(int index)? onDelete;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final bool isLocked;

  const ActionHistoryOverlay({
    Key? key,
    required this.actionHistory,
    required this.playerPositions,
    required this.expandedStreets,
    this.onToggleStreet,
    this.onEdit,
    this.onDelete,
    this.onReorder,
    required this.isLocked,
  }) : super(key: key);

  // Color helpers moved to [ActionFormattingHelper].

  @override
  Widget build(BuildContext context) {
    final Map<int, List<ActionEntry>> grouped = actionHistory.hudView();
    final screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth < 350 ? 0.8 : 1.0;
    const streetNames = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'];

    Widget buildChip(ActionEntry a, int index) {
      final pos = playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}';
      String? amountText;
      if (a.amount != null) {
        final formatted = ActionFormattingHelper.formatAmount(a.amount!);
        amountText = a.action == 'raise' ? 'to $formatted' : formatted;
      }
      final chip = Container(
        padding:
            EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        decoration: BoxDecoration(
          color: ActionFormattingHelper.actionColor(a.action)
              .withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$pos: ${a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action}',
              style: TextStyle(
                color: ActionFormattingHelper.actionTextColor(a.action),
                fontSize: 11 * scale,
              ),
            ),
            if (amountText != null) ...[
              const SizedBox(width: 4),
              Text(
                amountText,
                style: TextStyle(
                  color: ActionFormattingHelper.actionTextColor(a.action),
                  fontSize: 9 * scale,
                ),
              ),
            ],
          ],
        ),
      );

      Widget interactive = chip;

      if (!isLocked && (onEdit != null || onDelete != null)) {
        interactive = GestureDetector(
          onTap: onEdit == null
              ? null
              : () async {
                  final edited = await showEditActionDialog(
                    context,
                    entry: a,
                    numberOfPlayers: playerPositions.length,
                    playerPositions: playerPositions,
                  );
                  if (edited != null) {
                    final idx = actionHistory.indexOf(a);
                    if (idx != -1) onEdit!(idx, edited);
                  }
                },
          onLongPress: onDelete == null
              ? null
              : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Удалить действие?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final idx = actionHistory.indexOf(a);
                    if (idx != -1) {
                      actionHistory.removeAt(idx);
                      onDelete!(idx);
                    }
                  }
                },
          child: chip,
        );
      }

      if (onReorder != null && !isLocked) {
        return Row(
          key: ValueKey(a.timestamp.microsecondsSinceEpoch),
          mainAxisSize: MainAxisSize.min,
          children: [
            interactive,
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle,
                  color: Colors.white70, size: 16),
            ),
          ],
        );
      }

      return Container(
        key: ValueKey(a.timestamp.microsecondsSinceEpoch),
        child: interactive,
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.black38,
        height: 70 * scale,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) {
            final list = grouped[index] ?? [];
            if (list.isEmpty) {
              return const SizedBox.shrink();
            }
            final visibleList = list;
            return GestureDetector(
              onTap: () => onToggleStreet?.call(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streetNames[index],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * scale,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: onReorder != null && !isLocked
                          ? ReorderableListView.builder(
                              scrollDirection: Axis.horizontal,
                              buildDefaultDragHandles: false,
                              itemCount: visibleList.length,
                              onReorder: (oldIndex, newIndex) {
                                if (isLocked || onReorder == null) return;
                                final oldGlobal = actionHistory
                                    .indexOf(visibleList[oldIndex]);
                                int newGlobal;
                                if (newIndex >= visibleList.length) {
                                  newGlobal =
                                      actionHistory.indexOf(visibleList.last) +
                                          1;
                                } else {
                                  final target = visibleList[newIndex > oldIndex
                                      ? newIndex - 1
                                      : newIndex];
                                  newGlobal = actionHistory.indexOf(target);
                                  if (newIndex > oldIndex) newGlobal += 1;
                                }
                                onReorder!(oldGlobal, newGlobal);
                              },
                              itemBuilder: (context, i) =>
                                  buildChip(visibleList[i], i),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (int i = 0; i < visibleList.length; i++)
                                    buildChip(visibleList[i], i)
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
