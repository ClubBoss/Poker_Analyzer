import 'package:flutter/material.dart';

import '../models/v2/pack_ux_metadata.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/training_pack_progress_service.dart';

/// Displays a tooltip with basic metadata for a [TrainingPackTemplateV2].
///
/// The tooltip is shown on long press (mobile) or hover (desktop/web)
/// and contains the template's title, level, topic and format if
/// available. Missing or malformed metadata fields are ignored.
class TrainingPackTemplateTooltipWidget extends StatelessWidget {
  final TrainingPackTemplateV2 template;
  final Widget child;
  const TrainingPackTemplateTooltipWidget({
    super.key,
    required this.template,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final buffer = StringBuffer(template.name);
    final meta = template.meta;

    final level = _tryParse<TrainingPackLevel>(
        meta['level'], (v) => TrainingPackLevel.values.byName(v));
    final topic = _tryParse<TrainingPackTopic>(
        meta['topic'], (v) => TrainingPackTopic.values.byName(v));
    final format = _tryParse<TrainingPackFormat>(
        meta['format'], (v) => TrainingPackFormat.values.byName(v));

    if (level != null || topic != null || format != null) {
      buffer.writeln();
    }
    if (level != null) buffer.writeln('Level: ${_levelLabel(level)}');
    if (topic != null) buffer.writeln('Topic: ${_topicLabel(topic)}');
    if (format != null) buffer.writeln('Format: ${_formatLabel(format)}');

    final baseMessage = buffer.toString().trim();

    return FutureBuilder<TrainingPackProgressStats?>(
      future: TrainingPackProgressService.instance.getStatsForPack(template.id),
      builder: (context, snapshot) {
        var msg = baseMessage;
        final stats = snapshot.data;
        if (stats != null) {
          msg += '\nCompleted: ${stats.completedCount} / ${stats.totalCount}';
        }
        return Tooltip(message: msg, child: child);
      },
    );
  }

  T? _tryParse<T>(dynamic value, T Function(String) parser) {
    if (value is String) {
      try {
        return parser(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _levelLabel(TrainingPackLevel l) {
    switch (l) {
      case TrainingPackLevel.beginner:
        return 'Beginner';
      case TrainingPackLevel.intermediate:
        return 'Intermediate';
      case TrainingPackLevel.advanced:
        return 'Advanced';
    }
  }

  String _topicLabel(TrainingPackTopic t) {
    switch (t) {
      case TrainingPackTopic.pushFold:
        return 'Push/Fold Spots';
      case TrainingPackTopic.openFold:
        return 'Open/Fold Spots';
      case TrainingPackTopic.threeBet:
        return '3-Bet Spots';
      case TrainingPackTopic.postflop:
        return 'Postflop Spots';
    }
  }

  String _formatLabel(TrainingPackFormat f) {
    switch (f) {
      case TrainingPackFormat.cash:
        return 'Cash';
      case TrainingPackFormat.tournament:
        return 'Tournament';
    }
  }
}
