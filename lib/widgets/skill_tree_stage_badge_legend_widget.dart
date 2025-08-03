import 'package:flutter/material.dart';
import 'package:poker_analyzer/ui/padding_constants.dart';

import 'skill_tree_stage_badge_icon.dart';

/// Displays legend for stage badges with icons and explanations.
class SkillTreeStageBadgeLegendWidget extends StatelessWidget {
  const SkillTreeStageBadgeLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: kCardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendItem(badge: 'locked', text: 'Stage locked'),
          SizedBox(height: 4),
          _LegendItem(badge: 'in_progress', text: 'Stage in progress'),
          SizedBox(height: 4),
          _LegendItem(badge: 'perfect', text: 'Perfect completion'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String badge;
  final String text;

  const _LegendItem({required this.badge, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SkillTreeStageBadgeIcon(badge: badge),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
