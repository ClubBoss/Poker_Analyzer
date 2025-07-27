import 'package:flutter/material.dart';

import '../models/learning_path_stage_model.dart';
import '../models/learning_track_section_model.dart';
import '../widgets/learning_path_stage_tile.dart';

/// Displays a list of learning path stages using [LearningPathStageTile].
class LearningPathStageListScreen extends StatelessWidget {
  /// Stages to display.
  final List<LearningPathStageModel> stages;

  /// Optional sections for grouping.
  final List<LearningTrackSectionModel>? sections;

  const LearningPathStageListScreen({
    super.key,
    required this.stages,
    this.sections,
  });

  List<LearningPathStageModel> _sortedStages() {
    final list = List<LearningPathStageModel>.from(stages);
    list.sort((a, b) {
      if (a.order != b.order) return a.order.compareTo(b.order);
      final typeCmp = a.type.index.compareTo(b.type.index);
      if (typeCmp != 0) return typeCmp;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hasSections = sections != null && sections!.isNotEmpty;
    final sorted = _sortedStages();
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      body: hasSections
          ? _buildSectionedList(sorted)
          : _buildSimpleList(sorted),
    );
  }

  Widget _buildSimpleList(List<LearningPathStageModel> sorted) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (context, index) =>
          LearningPathStageTile(stage: sorted[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemCount: sorted.length,
    );
  }

  Widget _buildSectionedList(List<LearningPathStageModel> sorted) {
    final map = {for (final s in sorted) s.id: s};
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final section in sections!)
          _SectionWidget(
            section: section,
            stages: [
              for (final id in section.stageIds)
                if (map[id] != null) map[id]!,
            ],
          ),
      ],
    );
  }
}

class _SectionWidget extends StatelessWidget {
  final LearningTrackSectionModel section;
  final List<LearningPathStageModel> stages;

  const _SectionWidget({required this.section, required this.stages});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: Text(section.title),
      subtitle: section.description.isNotEmpty
          ? Text(section.description)
          : null,
      children: [
        for (int i = 0; i < stages.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == stages.length - 1 ? 0 : 4),
            child: LearningPathStageTile(stage: stages[i]),
          ),
      ],
    );
  }
}
