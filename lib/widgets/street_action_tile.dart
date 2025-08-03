import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../helpers/action_evaluation_helper.dart';
import '../models/action_entry.dart';
import '../services/user_preferences_service.dart';
import 'chip_stack_widget.dart';
import 'edit_action_dialog.dart';

/// Tile widget displaying a single action entry on a street.
class StreetActionTile extends StatelessWidget {
  final ActionEntry entry;
  final ActionEntry? previousEntry;
  final int index;
  final int globalIndex;
  final int numberOfPlayers;
  final Map<int, String> playerPositions;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final void Function(int)? onDuplicate;
  final int? visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;
  final void Function(ActionEntry, String?)? onManualEvaluationChanged;
  final bool showDragHandle;

  const StreetActionTile({
    super.key,
    required this.entry,
    this.previousEntry,
    required this.index,
    required this.globalIndex,
    required this.numberOfPlayers,
    required this.playerPositions,
    required this.onEdit,
    required this.onDelete,
    this.onDuplicate,
    this.visibleCount,
    this.evaluateActionQuality,
    this.onManualEvaluationChanged,
    this.showDragHandle = false,
  });

  Color _actionColor(String action) {
    switch (action) {
      case 'fold':
        return Colors.red;
      case 'call':
        return Colors.blue;
      case 'raise':
        return Colors.green;
      case 'check':
        return Colors.grey;
      case 'custom':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  String _formatTimestamp() {
    if (previousEntry != null) {
      final diff = entry.timestamp.difference(previousEntry!.timestamp).inSeconds;
      if (diff > 0 && diff < 60) {
        return '+${diff}s';
      }
    }
    return '⏱ ${DateFormat('HH:mm', Intl.getCurrentLocale()).format(entry.timestamp)}';
  }

  String _buildTooltipMessage(String? qualityLabel) {
    final buffer = StringBuffer(
        'Время: ${DateFormat('HH:mm:ss', Intl.getCurrentLocale()).format(entry.timestamp)}');
    if (previousEntry != null) {
      final diffMs =
          entry.timestamp.difference(previousEntry!.timestamp).inMilliseconds;
      final diffSec = diffMs / 1000;
      buffer.writeln('\nС момента прошлого действия: +${diffSec.toStringAsFixed(1)} сек');
    }
    if (qualityLabel != null) {
      buffer.writeln('\nОценка: $qualityLabel');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(entry.action);
    final pos = playerPositions[entry.playerIndex] ?? 'P${entry.playerIndex + 1}';
    final actLabel = entry.action == 'custom'
        ? (entry.customLabel ?? 'custom')
        : entry.action;
    final baseTitle = '$pos — $actLabel';
    final title = entry.generated ? '$baseTitle (auto)' : baseTitle;

    Color? qualityColor;
    String? qualityLabel;
    if (evaluateActionQuality != null && visibleCount != null) {
      final q = entry.manualEvaluation ?? evaluateActionQuality!(entry);
      switch (q) {
        case 'Лучшая линия':
          qualityColor = Colors.green;
          qualityLabel = q;
          break;
        case 'Нормальная линия':
          qualityColor = Colors.yellow;
          qualityLabel = q;
          break;
        case 'Ошибка':
          qualityColor = Colors.red;
          qualityLabel = q;
          break;
      }
    }

    final tile = ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (entry.amount != null) ...[
            ChipStackWidget(
              amount: entry.amount!,
              scale: 0.7,
              color: color,
            ),
            const SizedBox(width: 6),
          ],
          if (entry.amount != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${entry.amount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (entry.amount != null) const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontStyle:
                    entry.generated ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
      onTap: () async {
        final edited = await showEditActionDialog(
          context,
          entry: entry,
          numberOfPlayers: numberOfPlayers,
          playerPositions: playerPositions,
        );
        if (edited != null) {
          onEdit(globalIndex, edited);
        }
      },
      onLongPress: onDuplicate == null
          ? null
          : () async {
              final dup = await showDialog<bool>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Выберите действие'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Дублировать'),
                    ),
                  ],
                ),
              );
              if (dup == true) {
                onDuplicate!(globalIndex);
              }
            },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDragHandle)
            ReorderableDragStartListener(
              index: index,
              child:
                  const Icon(Icons.drag_handle, color: Colors.white70, size: 20),
            ),
          if (!entry.generated)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                _formatTimestamp(),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          if (qualityLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onLongPress: onManualEvaluationChanged == null
                    ? null
                    : () async {
                        final result =
                            await showActionEvaluationDialog(context);
                        if (result != null) {
                          onManualEvaluationChanged!(entry, result);
                        }
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: qualityColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        qualityLabel,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (entry.manualEvaluation != null &&
                        onManualEvaluationChanged != null)
                      GestureDetector(
                        onTap: () => onManualEvaluationChanged!(entry, null),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => onDelete(globalIndex),
          ),
        ],
      ),
    );

    final prefs = context.watch<UserPreferencesService>();
    if (!prefs.showActionHints || entry.generated) return tile;

    return Tooltip(
      message: _buildTooltipMessage(qualityLabel),
      preferBelow: false,
      child: tile,
    );
  }
}

