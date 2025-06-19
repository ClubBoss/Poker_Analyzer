import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'edit_action_dialog.dart';
import 'package:intl/intl.dart';

import 'street_pot_widget.dart';
import 'package:provider/provider.dart';
import '../services/user_preferences_service.dart';

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
  final int? visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;
  final void Function(ActionEntry, String?)? onManualEvaluationChanged;

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
    this.visibleCount,
    this.evaluateActionQuality,
    this.onManualEvaluationChanged,
  });

  Widget _buildTile(BuildContext context, ActionEntry a, int globalIndex) {
    Color color;
    switch (a.action) {
      case 'fold':
        color = Colors.red;
        break;
      case 'call':
        color = Colors.blue;
        break;
      case 'raise':
        color = Colors.green;
        break;
      case 'check':
        color = Colors.grey;
        break;
      default:
        color = Colors.white;
    }
    final pos =
        playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}';
    final baseTitle = '$pos — ${a.action}';
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                        qualityLabel!,
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
    return '⏱ ${DateFormat('HH:mm').format(a.timestamp)}';
  }

  String _buildTooltipMessage(
      ActionEntry a, int index, String? qualityLabel) {
    final buffer = StringBuffer(
        'Время: ${DateFormat('HH:mm:ss').format(a.timestamp)}');
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
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (int index = 0; index < streetActions.length; index++) ...[
                  if (index > 0 &&
                      (streetActions[index].action == 'bet' ||
                          streetActions[index].action == 'raise'))
                    const Divider(height: 4, color: Colors.white24),
                  _buildTile(context, streetActions[index],
                      actions.indexOf(streetActions[index])),
                ]
              ],
            ),
          ),
        StreetPotWidget(
          streetIndex: street,
          potSize: pots[street],
        ),
      ],
    );
  }
}
