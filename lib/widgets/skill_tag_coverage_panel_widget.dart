import 'package:flutter/material.dart';

import '../services/skill_tag_coverage_tracker_service.dart';

/// Displays tags with the lowest coverage based on generation logs.
class SkillTagCoveragePanelWidget extends StatefulWidget {
  final Set<String> requiredTags;
  const SkillTagCoveragePanelWidget({super.key, this.requiredTags = const {}});

  @override
  State<SkillTagCoveragePanelWidget> createState() =>
      _SkillTagCoveragePanelWidgetState();
}

class _SkillTagCoveragePanelWidgetState
    extends State<SkillTagCoveragePanelWidget> {
  final SkillTagCoverageTrackerService _service =
      SkillTagCoverageTrackerService();

  late Future<Map<String, int>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _service.getTagUsageCount();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _countsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final counts = snapshot.data!;
        final allTags = {...widget.requiredTags, ...counts.keys};
        final entries = [
          for (final tag in allTags)
            MapEntry(tag, counts[tag.trim().toLowerCase()] ?? 0)
        ]
          ..sort((a, b) => a.value.compareTo(b.value));
        final top = entries.take(5).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skill Tag Coverage',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (top.isEmpty)
                  const Text('No data')
                else
                  for (final e in top)
                    Text('• ${e.key}: ${e.value}')
              ],
            ),
          ),
        );
      },
    );
  }
}

