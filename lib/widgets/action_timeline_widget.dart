import 'package:flutter/material.dart';
import '../models/action_entry.dart';

/// Displays a timeline of all visible actions with interaction support.
class ActionTimelineWidget extends StatelessWidget {
  final List<ActionEntry> actions;
  final int playbackIndex;
  final Function(int index) onTap;
  final Map<int, String>? playerPositions;
  final double scale;
  final ScrollController? controller;
  final int? focusPlayerIndex;

  const ActionTimelineWidget({
    Key? key,
    required this.actions,
    required this.playbackIndex,
    required this.onTap,
    this.playerPositions,
    this.scale = 1.0,
    this.controller,
    this.focusPlayerIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48 * scale,
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          final isSelected = index == playbackIndex;
          final pos = playerPositions?[action.playerIndex] ??
              'P${action.playerIndex + 1}';
          final dim = focusPlayerIndex != null &&
              action.playerIndex != focusPlayerIndex;

          return GestureDetector(
            onTap: () => onTap(index),
            child: Opacity(
              opacity: dim ? 0.3 : 1.0,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4 * scale),
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * scale,
                  vertical: 6 * scale,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8 * scale),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  '$pos ${action.action}${action.amount != null ? ' ${action.amount}' : ''}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12 * scale,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
