import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'detailed_action_bottom_sheet.dart';

/// Список действий на конкретной улице
class StreetActionsList extends StatelessWidget {
  final int street;
  final List<ActionEntry> actions;
  final List<int> pots;
  final Map<int, int> stackSizes;
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
    required this.onEdit,
    required this.onDelete,
    this.visibleCount,
    this.evaluateActionQuality,
  });

  Widget _buildTile(BuildContext context, ActionEntry a, int globalIndex) {
    final amountStr = a.amount != null ? ' ${a.amount}' : '';
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
    final title = a.generated
        ? 'Игрок ${a.playerIndex + 1}: ${a.action}$amountStr (auto)'
        : 'Игрок ${a.playerIndex + 1}: ${a.action}$amountStr';

    String? icon;
    if (evaluateActionQuality != null && visibleCount != null) {
      final quality = evaluateActionQuality!(a);
      switch (quality) {
        case 'good':
          icon = '🟢';
          break;
        case 'ok':
          icon = '🟡';
          break;
        case 'bad':
          icon = '🔴';
          break;
      }
    }
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading:
          icon != null ? Text(icon!, style: const TextStyle(fontSize: 16)) : null,
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontStyle: a.generated ? FontStyle.italic : FontStyle.normal,
        ),
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
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => onDelete(globalIndex),
      ),
    );
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
      ],
    );
  }
}
