import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'edit_action_dialog.dart';
import 'package:intl/intl.dart';
import '../helpers/action_color_helper.dart';

import 'street_pot_widget.dart';
import 'chip_stack_widget.dart';
import 'package:provider/provider.dart';
import '../services/user_preferences_service.dart';
import '../utils/snackbar_util.dart';

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

  Widget _buildTile(
      BuildContext context, ActionEntry a, int globalIndex, int index) {
    final color = actionColor(a.action);
    final pos = playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}';
    final actLabel = a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action;
    final baseTitle = '$pos — $actLabel';
    final title = a.generated ? '$baseTitle (auto)' : baseTitle;

    Color? qualityColor;
    String? qualityLabel;
    if (evaluateActionQuality != null && visibleCount != null) {
      final q = a.manualEvaluation ?? evaluateActionQuality!(a);
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
          if (a.amount != null) ...[
            ChipStackWidget(
              amount: a.amount!,
              scale: 0.7,
              color: color,
            ),
            const SizedBox(width: 6),
          ],
          if (a.amount != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${a.amount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (a.amount != null) const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontStyle: a.generated ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
      onTap: () async {
        final edited = await showEditActionDialog(
          context,
          entry: a,
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
          if (onReorder != null)
            ReorderableDragStartListener(
              index: index,
              child:
                  const Icon(Icons.drag_handle, color: Colors.white70, size: 20),
            ),
          if (!a.generated)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                _formatTimestamp(globalIndex, a),
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
                        final result = await showDialog<String>(
                          context: context,
                          builder: (ctx) => SimpleDialog(
                            title: const Text('Оценить действие'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'Лучшая линия'),
                                child: const Text('Лучшая линия'),
                              ),
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'Нормальная линия'),
                                child: const Text('Нормальная линия'),
                              ),
                              SimpleDialogOption(
                                onPressed: () => Navigator.pop(ctx, 'Ошибка'),
                                child: const Text('Ошибка'),
                              ),
                            ],
                          ),
                        );
                        if (result != null) {
                          onManualEvaluationChanged!(a, result);
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
                    if (a.manualEvaluation != null &&
                        onManualEvaluationChanged != null)
                      GestureDetector(
                        onTap: () =>
                            onManualEvaluationChanged!(a, null),
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
    if (!prefs.showActionHints || a.generated) return tile;

    return Tooltip(
      message: _buildTooltipMessage(a, globalIndex, qualityLabel),
      preferBelow: false,
      child: tile,
    );
  }

  String _formatTimestamp(int index, ActionEntry a) {
    if (index > 0) {
      final prev = actions[index - 1];
      final diff = a.timestamp.difference(prev.timestamp).inSeconds;
      if (diff > 0 && diff < 60) {
        return '+${diff}s';
      }
    }
    return '⏱ ${DateFormat('HH:mm', Intl.getCurrentLocale()).format(a.timestamp)}';
  }

  String _buildTooltipMessage(
      ActionEntry a, int index, String? qualityLabel) {
    final buffer = StringBuffer(
        'Время: ${DateFormat('HH:mm:ss', Intl.getCurrentLocale()).format(a.timestamp)}');
    if (index > 0) {
      final prev = actions[index - 1];
      final diffMs =
          a.timestamp.difference(prev.timestamp).inMilliseconds;
      final diffSec = diffMs / 1000;
      buffer.writeln(
          '\nС момента прошлого действия: +${diffSec.toStringAsFixed(1)} сек');
    }
    if (qualityLabel != null) {
      buffer.writeln('\nОценка: $qualityLabel');
    }
    return buffer.toString();
  }

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
                    SnackbarUtil.showMessage(context, 'Действие удалено', action: SnackBarAction(
                          label: 'Отмена',
                          onPressed: () {
                            if (onInsert != null) {
                              onInsert!(index, entry);
                            }
                          },
                        ));
                  },
                  child: Column(
                    children: [
                      if (showDivider)
                        const Divider(height: 4, color: Colors.white24),
                      _buildTile(
                          context, entry, actions.indexOf(entry), index),
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
