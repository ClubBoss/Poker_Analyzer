import 'package:flutter/material.dart';

/// Displays a badge icon for a skill tree stage based on [badge].
///
/// The [badge] parameter accepts `locked`, `in_progress`, or `perfect` and
/// renders the appropriate icon with a tooltip. Unknown values render nothing.
class SkillTreeStageBadgeIcon extends StatelessWidget {
  final String badge;

  const SkillTreeStageBadgeIcon({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    Color? color;
    String? tooltip;

    switch (badge) {
      case 'locked':
        icon = Icons.lock_outline;
        color = Colors.grey;
        tooltip = 'Stage locked';
        break;
      case 'in_progress':
        icon = Icons.hourglass_bottom;
        color = Colors.amber;
        tooltip = 'In progress';
        break;
      case 'perfect':
        icon = Icons.verified;
        color = Colors.green;
        tooltip = 'Perfect';
        break;
    }

    if (icon == null || tooltip == null) return const SizedBox.shrink();

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 20),
    );
  }
}
