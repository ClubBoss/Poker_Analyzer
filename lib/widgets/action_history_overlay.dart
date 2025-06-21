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

    Widget buildDraggableChip(ActionEntry a, {bool highlight = false}) {
      final pos = playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}';
      String? amountText;
      if (a.amount != null) {
        final formatted = ActionFormattingHelper.formatAmount(a.amount!);
        amountText = a.action == 'raise' ? 'to $formatted' : formatted;
      }
      Color baseColor =
          ActionFormattingHelper.actionColor(a.action).withOpacity(0.8);
      if (highlight) {
        baseColor = baseColor.withOpacity(1.0);
      }

      final chip = Container(
        padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$pos: ${a.action}',
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

      Widget content = chip;
      if (onEdit != null && !isLocked) {
        content = GestureDetector(
          onTap: () async {
            final edited = await showEditActionDialog(
              context,
              entry: a,
              numberOfPlayers: playerPositions.length,
              playerPositions: playerPositions,
            );
            if (edited != null) {
              final index = actionHistory.indexOf(a);
              if (index != -1) onEdit!(index, edited);
            }
          },
          onLongPress: onDelete == null
              ? null
              : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Удалить действие?'),
                      content:
                          const Text('Вы уверены, что хотите удалить действие?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Нет'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Да'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final index = actionHistory.indexOf(a);
                    if (index != -1) onDelete!(index);
                  }
                },
          child: chip,
        );
      }

      if (onReorder != null && !isLocked) {
        final index = actionHistory.indexOf(a);
        final left = IconButton(
          icon: const Icon(Icons.arrow_upward, size: 14, color: Colors.white),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onReorder!(index, index - 1),
        );
        final right = IconButton(
          icon: const Icon(Icons.arrow_downward, size: 14, color: Colors.white),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onReorder!(index, index + 1),
        );
        final handle = LongPressDraggable<ActionEntry>(
          data: a,
          feedback: Material(
            type: MaterialType.transparency,
            child: chip,
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: chip),
          child: const Icon(Icons.drag_handle, color: Colors.white70, size: 14),
        );

        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [handle, left, content, right],
        );
      }

      return content;
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final a in visibleList)
                              DragTarget<ActionEntry>(
                                onWillAccept: (data) =>
                                    onReorder != null && !isLocked && data != a,
                                onAccept: (data) {
                                  if (onReorder == null || isLocked) return;
                                  final oldIndex = actionHistory.indexOf(data);
                                  final newIndex = actionHistory.indexOf(a);
                                  if (oldIndex != -1 && newIndex != -1) {
                                    onReorder!(oldIndex, newIndex);
                                  }
                                },
                                builder: (context, candidate, rejected) =>
                                    buildDraggableChip(a,
                                        highlight: candidate.isNotEmpty),
                              ),
                            if (onReorder != null && !isLocked)
                              DragTarget<ActionEntry>(
                                onWillAccept: (_) => true,
                                onAccept: (data) {
                                  final oldIndex = actionHistory.indexOf(data);
                                  final lastIndex =
                                      actionHistory.indexOf(visibleList.last);
                                  if (oldIndex != -1) {
                                    onReorder!(oldIndex, lastIndex + 1);
                                  }
                                },
                                builder: (context, candidate, rejected) =>
                                    const SizedBox(width: 4),
                              ),
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
