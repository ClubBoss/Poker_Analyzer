import 'package:flutter/material.dart';

import '../models/action_entry.dart';
import '../helpers/action_formatting_helper.dart';
import '../services/action_history_service.dart';

class ActionHistoryOverlay extends StatelessWidget {
  final ActionHistoryService actionHistory;
  final Map<int, String> playerPositions;
  final Set<int> expandedStreets;
  final ValueChanged<int>? onToggleStreet;

  const ActionHistoryOverlay({
    Key? key,
    required this.actionHistory,
    required this.playerPositions,
    required this.expandedStreets,
    this.onToggleStreet,
  }) : super(key: key);

  // Color helpers moved to [ActionFormattingHelper].

  @override
  Widget build(BuildContext context) {
    final Map<int, List<ActionEntry>> grouped = actionHistory.hudView();
    final screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth < 350 ? 0.8 : 1.0;
    const streetNames = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'];

    Widget buildChip(ActionEntry a) {
      final pos = playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}';
      String? amountText;
      if (a.amount != null) {
        final formatted = ActionFormattingHelper.formatAmount(a.amount!);
        amountText = a.action == 'raise' ? 'to $formatted' : formatted;
      }
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        decoration: BoxDecoration(
          color: ActionFormattingHelper.actionColor(a.action).withOpacity(0.8),
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
                          children: [for (final a in visibleList) buildChip(a)],
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
