import 'package:flutter/material.dart';

import '../models/action_entry.dart';
import '../helpers/action_formatting_helper.dart';

class ActionHistoryOverlay extends StatelessWidget {
  final List<ActionEntry> actions;
  final int playbackIndex;
  final Map<int, String> playerPositions;
  final Set<int> expandedStreets;
  final ValueChanged<int>? onToggleStreet;

  const ActionHistoryOverlay({
    Key? key,
    required this.actions,
    required this.playbackIndex,
    required this.playerPositions,
    required this.expandedStreets,
    this.onToggleStreet,
  }) : super(key: key);

  // Color helpers moved to [ActionFormattingHelper].

  @override
  Widget build(BuildContext context) {
    final visible = actions.take(playbackIndex).toList();
    final Map<int, List<ActionEntry>> grouped =
        {for (var i = 0; i < 4; i++) i: <ActionEntry>[]};
    for (final a in visible) {
      grouped[a.street]?.add(a);
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth < 350 ? 0.8 : 1.0;
    const streetNames = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'];

    Widget buildChip(ActionEntry a) {
      final pos = playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}';
      final text = '$pos: ${a.action}${a.amount != null ? ' ${a.amount}' : ''}';
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        decoration: BoxDecoration(
          color: ActionFormattingHelper.actionColor(a.action).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: ActionFormattingHelper.actionTextColor(a.action),
            fontSize: 11 * scale,
          ),
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
            final expanded = expandedStreets.contains(index);
            final visibleList = expanded || list.length <= 5
                ? list
                : list.sublist(list.length - 5);
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
