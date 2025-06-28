import 'package:flutter/material.dart';
import '../../models/action_entry.dart';
import '../action_timeline_widget.dart';

class ActionTimelinePanel extends StatelessWidget {
  final List<ActionEntry> actions;
  final int playbackIndex;
  final ValueChanged<int> onTap;
  final Map<int, String> playerPositions;
  final int? focusPlayerIndex;
  final ScrollController controller;
  final double scale;
  final bool locked;

  const ActionTimelinePanel({
    super.key,
    required this.actions,
    required this.playbackIndex,
    required this.onTap,
    required this.playerPositions,
    required this.focusPlayerIndex,
    required this.controller,
    required this.scale,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: locked,
      child: ActionTimelineWidget(
        actions: actions,
        playbackIndex: playbackIndex,
        onTap: onTap,
        playerPositions: playerPositions,
        focusPlayerIndex: focusPlayerIndex,
        controller: controller,
        scale: scale,
      ),
    );
  }
}
