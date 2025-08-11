import 'package:flutter/material.dart';

import '../models/v2/pack_ux_metadata.dart';
import '../models/v2/training_pack_template_v2.dart';

class PackPreviewScreenMetadataSection extends StatelessWidget {
  final TrainingPackTemplateV2 template;
  const PackPreviewScreenMetadataSection({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final meta = template.meta;

    TrainingPackLevel? level;
    TrainingPackTopic? topic;
    TrainingPackFormat? format;
    TrainingPackComplexity? complexity;

    try {
      final v = meta['level'];
      if (v is String) level = TrainingPackLevel.values.byName(v);
    } catch (_) {}
    try {
      final v = meta['topic'];
      if (v is String) topic = TrainingPackTopic.values.byName(v);
    } catch (_) {}
    try {
      final v = meta['format'];
      if (v is String) format = TrainingPackFormat.values.byName(v);
    } catch (_) {}
    try {
      final v = meta['complexity'];
      if (v is String) {
        complexity = TrainingPackComplexity.values.byName(v);
      }
    } catch (_) {}

    final items = <Widget>[];
    if (level != null) {
      items.add(_MetaItem(icon: Icons.school, label: _levelLabel(level)));
    }
    if (topic != null) {
      items.add(_MetaItem(icon: Icons.topic, label: _topicLabel(topic)));
    }
    if (format != null) {
      final icon = format == TrainingPackFormat.cash
          ? Icons.attach_money
          : Icons.emoji_events;
      items.add(_MetaItem(icon: icon, label: _formatLabel(format)));
    }
    if (complexity != null) {
      items.add(
        _MetaItem(icon: Icons.tune, label: _complexityLabel(complexity)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty) Wrap(spacing: 8, runSpacing: 4, children: items),
        if (template.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: template.tags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (_, i) => Chip(label: Text(template.tags[i])),
              ),
            ),
          ),
      ],
    );
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
        return 'Push/Fold';
      case TrainingPackTopic.openFold:
        return 'Open/Fold';
      case TrainingPackTopic.threeBet:
        return '3-Bet';
      case TrainingPackTopic.postflop:
        return 'Postflop';
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

  String _complexityLabel(TrainingPackComplexity c) {
    switch (c) {
      case TrainingPackComplexity.simple:
        return 'Simple';
      case TrainingPackComplexity.multiStreet:
        return 'Multi-Street';
      case TrainingPackComplexity.icm:
        return 'ICM';
    }
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
