import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'detailed_action_bottom_sheet.dart';
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
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final int? visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;

  const StreetActionsList({
    super.key,
    required this.street,
    required this.actions,
    required this.pots,
    required this.stackSizes,
    required this.playerPositions,
    required this.onEdit,
    required this.onDelete,
    this.visibleCount,
    this.evaluateActionQuality,
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

    String? qualityText;
    if (evaluateActionQuality != null && visibleCount != null) {
      final q = evaluateActionQuality!(a).toLowerCase();
      if (q.contains('good')) {
        qualityText = '🟢 GOOD';
      } else if (q.contains('marginal') || q.contains('ok')) {
        qualityText = '🟡 MARGINAL';
      } else if (q.contains('mistake') || q.contains('bad')) {
        qualityText = '🔴 MISTAKE';
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
        final result = await showDetailedActionBottomSheet(
          context,
          potSizeBB: pots[a.street],
          stackSizeBB: stackSizes[a.playerIndex] ?? 0,
          currentStreet: a.street,
          initialAction: a.action,
          initialAmount: a.amount,
        );
        if (result != null) {
          final entry = ActionEntry(
            result['street'] as int,
            a.playerIndex,
            result['action'] as String,
            amount: result['amount'] as int?,
          );
          onEdit(globalIndex, entry);
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
          if (qualityText != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                qualityText!,
                style: const TextStyle(fontSize: 12),
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
      message: _buildTooltipMessage(a, globalIndex, qualityText),
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
      ActionEntry a, int index, String? qualityText) {
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
    if (qualityText != null) {
      buffer.writeln('\nОценка: $qualityText');
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
