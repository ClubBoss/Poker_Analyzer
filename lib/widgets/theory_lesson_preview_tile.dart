import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/booster_lesson_status.dart';
import '../services/booster_lesson_status_service.dart';
import '../theme/app_colors.dart';
import 'tag_badge.dart';

/// Preview tile for a [TheoryMiniLessonNode].
class TheoryLessonPreviewTile extends StatelessWidget {
  /// Lesson to display.
  final TheoryMiniLessonNode node;

  /// Callback when tile is tapped.
  final VoidCallback? onTap;

  /// Whether this lesson is the current active one.
  final bool isCurrent;

  const TheoryLessonPreviewTile({
    super.key,
    required this.node,
    this.onTap,
    this.isCurrent = false,
  });

  String _shortDescription(String text, {int max = 80}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}…';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final border = isCurrent ? Border.all(color: accent, width: 2) : null;
    return FutureBuilder<BoosterLessonStatus>(
      future: BoosterLessonStatusService.instance.getStatus(node),
      builder: (context, snapshot) {
        final status = snapshot.data;
        Widget? badge;
        if (status != null) {
          badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: status.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.label,
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: border ?? BorderSide.none),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          node.resolvedTitle,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (badge != null) badge,
                    ],
                  ),
                  if (node.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: -4,
                        children: [
                          for (final t in node.tags.take(3)) TagBadge(t)
                        ],
                      ),
                    ),
                  if (node.resolvedContent.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _shortDescription(node.resolvedContent),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
