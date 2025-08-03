import 'package:flutter/material.dart';
import 'package:poker_analyzer/ui/padding_constants.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_progress_stats.dart';

/// Displays detailed progress for a learning path with section breakdowns.
class LearningPathProgressWidget extends StatefulWidget {
  final LearningPathProgressStats stats;
  final LearningPathTemplateV2 template;
  final bool showLockedInitially;

  const LearningPathProgressWidget({
    super.key,
    required this.stats,
    required this.template,
    this.showLockedInitially = false,
  });

  @override
  State<LearningPathProgressWidget> createState() => _LearningPathProgressWidgetState();
}

class _LearningPathProgressWidgetState extends State<LearningPathProgressWidget> {
  late bool _showLocked;

  @override
  void initState() {
    super.initState();
    _showLocked = widget.showLockedInitially;
  }

  String _stageTitle(String id) {
    final stage = widget.template.stages.firstWhere(
      (s) => s.id == id,
      orElse: () => throw ArgumentError('Stage $id not found'),
    );
    return stage.title;
  }

  Widget _buildSection(SectionStats section, Color accent) {
    final pct = (section.completionPercent.clamp(0.0, 1.0) * 100).round();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: kCardPadding,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text('${section.completedStages}/${section.totalStages}',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: section.completionPercent.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 2),
          Text('$pct%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLockedStages() {
    final accent = Theme.of(context).colorScheme.secondary;
    if (widget.stats.lockedStageIds.isEmpty) return const SizedBox.shrink();
    final titles = widget.stats.lockedStageIds.map(_stageTitle).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showLocked = !_showLocked),
          child: Row(
            children: [
              Icon(_showLocked ? Icons.expand_less : Icons.lock,
                  color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                'Заблокированные стадии (${titles.length})',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        if (_showLocked)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in titles)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $t',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final pct = (widget.stats.completionPercent.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.stats.completedStages}/${widget.stats.totalStages} стадий — $pct%',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.stats.completionPercent.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.stats.sections.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in widget.stats.sections) _buildSection(s, accent),
                const SizedBox(height: 8),
              ],
            ),
          _buildLockedStages(),
        ],
      ),
    );
  }
}

