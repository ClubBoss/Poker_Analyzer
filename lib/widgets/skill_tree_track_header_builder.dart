import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_track_progress_service.dart';
import '../services/skill_tree_category_banner_service.dart';

/// Builds a header widget with metadata for a skill tree track.
class SkillTreeTrackHeaderBuilder {
  final SkillTreeCategoryBannerService bannerService;

  const SkillTreeTrackHeaderBuilder({
    SkillTreeCategoryBannerService? bannerService,
  }) : bannerService = bannerService ?? const SkillTreeCategoryBannerService();

  /// Returns a widget displaying [root] info and [progress].
  Widget build({
    required SkillTreeNodeModel root,
    required TrackProgressEntry progress,
    Map<String, Widget>? iconMap,
    bool compact = false,
  }) {
    final visual = bannerService.getVisual(root.category);
    final accent = visual.color;
    final iconWidget = iconMap?[root.category] ??
        Text(visual.emoji, style: const TextStyle(fontSize: 20));
    final pct = (progress.completionRate.clamp(0.0, 1.0) * 100).round();

    final progressBar = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress.completionRate.clamp(0.0, 1.0),
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation<Color>(accent),
        minHeight: 6,
      ),
    );

    final status = progress.isCompleted
        ? const Icon(Icons.check_circle, color: Colors.green)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              progressBar,
              const SizedBox(height: 4),
              Text(
                '$pct%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          );

    if (compact) {
      return Row(
        children: [
          CircleAvatar(backgroundColor: accent, child: iconWidget),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  root.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (!progress.isCompleted) ...[
                  const SizedBox(height: 4),
                  progressBar,
                  const SizedBox(height: 4),
                  Text(
                    '$pct%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: accent, child: iconWidget),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    root.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    root.category,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            status,
          ],
        ),
        if (!progress.isCompleted) ...[const SizedBox(height: 8), progressBar],
      ],
    );
  }
}
