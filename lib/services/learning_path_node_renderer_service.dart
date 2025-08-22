import 'dart:async';

import 'package:flutter/material.dart';

import 'learning_path_entry_group_builder.dart';
import 'learning_path_entry_renderer.dart';
import 'learning_path_node_analytics_logger.dart';
import 'theory_auto_recall_injector.dart';

/// Renders groups of learning path entries into titled sections.
class LearningPathNodeRendererService {
  final LearningPathEntryRenderer entryRenderer;
  final LearningPathNodeAnalyticsLogger analyticsLogger;
  final TheoryAutoRecallInjector autoRecall;

  LearningPathNodeRendererService({
    LearningPathEntryRenderer? entryRenderer,
    LearningPathNodeAnalyticsLogger? analyticsLogger,
    TheoryAutoRecallInjector? autoRecall,
  }) : entryRenderer = entryRenderer ?? const LearningPathEntryRenderer(),
       analyticsLogger =
           analyticsLogger ?? const LearningPathNodeAnalyticsLogger(),
       autoRecall = autoRecall ?? const TheoryAutoRecallInjector();

  /// Builds a column widget displaying [groups] with headers and entry cards.
  Widget build(
    BuildContext context,
    String nodeId,
    List<LearningPathEntryGroup> groups,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) _buildGroup(context, nodeId, group),
      ],
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String nodeId,
    LearningPathEntryGroup group,
  ) {
    unawaited(analyticsLogger.logGroupViewed(nodeId, group.title));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          child: Text(
            group.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        for (final entry in group.entries) ...[
          entryRenderer.build(context, entry),
          autoRecall.build(context, nodeId, entry),
        ],
      ],
    );
  }
}
