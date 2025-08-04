import 'package:flutter/material.dart';

import 'learning_path_entry_group_builder.dart';
import 'learning_path_entry_renderer.dart';

/// Renders groups of learning path entries into titled sections.
class LearningPathNodeRendererService {
  final LearningPathEntryRenderer entryRenderer;

  const LearningPathNodeRendererService({
    LearningPathEntryRenderer? entryRenderer,
  }) : entryRenderer = entryRenderer ?? const LearningPathEntryRenderer();

  /// Builds a column widget displaying [groups] with headers and entry cards.
  Widget build(BuildContext context, List<LearningPathEntryGroup> groups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.only(
                top: 16, left: 16, right: 16, bottom: 8),
            child: Text(
              group.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          for (final entry in group.entries)
            entryRenderer.build(context, entry),
        ],
      ],
    );
  }
}

